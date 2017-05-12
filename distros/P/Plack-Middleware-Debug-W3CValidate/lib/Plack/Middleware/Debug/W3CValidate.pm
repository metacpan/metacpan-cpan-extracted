package Plack::Middleware::Debug::W3CValidate;

our $VERSION = '0.04';
use 5.008;
use strict;
use warnings;
use parent qw(Plack::Middleware::Debug::Base);

use XML::XPath;
use WebService::Validator::HTML::W3C;
use Plack::Util::Accessor qw(validator_uri);

my $table_template = __PACKAGE__->build_template(<<'TABLETMPL');
% my $errs = shift @_;
<style>
    #validation_errors td strong {
        color: red;
    }
</style>
<table id="validation_errors">
    <thead>
        <tr>
            <th>Line</th>
            <th>Column</th>
            <th>Message</th>
            <th>Source</th>
        </tr>
    </thead>
    <tbody>
% my $i = 0;
% for my $error (@$errs) {
        <tr class="<%= ++$i % 2 ? 'plDebugOdd' : 'plDebugEven' %>">
            <td><%= $error->{line} %></td>
            <td><%= $error->{col} %></td>
            <td><%= $error->{msg} %></td>
            <td><%= Text::MicroTemplate::encoded_string($error->{source}) %></td>
        </tr>
% }
    </tbody>
</table>
TABLETMPL

sub get_validator {
    my $self = shift @_;
    my %opts = ($self->validator_uri ? (validator_uri=>$self->validator_uri) : ());
    return WebService::Validator::HTML::W3C->new(detailed=>1, %opts);
}

sub flatten_body {
    my ($self, $res) = @_;
    my $body = $res->[2];
    if(ref $body eq 'ARRAY') {
        return join "", @$body;
    } elsif(defined $body) {
        my $slurped;
        while (defined(my $line = $body->getline)) {
            $slurped .= $line if length $line;
        }
        return $slurped;
    }
}

## Until (and if) WebService::Validator::HTML::W3C parses for source
sub parse_for_errors {
    my ($self, $xml) = @_;
    my $xp = XML::XPath->new(xml => $xml);
    my @messages = $xp->findnodes( '/env:Envelope/env:Body/m:markupvalidationresponse/m:errors/m:errorlist/m:error' );

    my @errs;
    foreach my $msg ( @messages ) {
        my $err = { 
            line => $xp->find( './m:line', $msg )->get_node(1)->getChildNode(1)->getValue,
            col => $xp->find( './m:col', $msg )->get_node(1)->getChildNode(1)->getValue,
            msg => $xp->find( './m:message', $msg )->get_node(1)->getChildNode(1)->getValue,
            source => $xp->find( './m:source', $msg )->get_node(1)->getChildNode(1)->getValue,  
        };
        push @errs, $err;
    }
    return @errs;
}

sub run {
    my($self, $env, $panel) = @_;
    $panel->title("W3C Validation");
    $panel->nav_title("W3C Validation");
    return sub {
        my $res = shift @_;
        my $v = $self->get_validator;
        my $slurped_body = $self->flatten_body($res);
        if($v->validate_markup($slurped_body)) {
            if ( $v->is_valid ) {
                $panel->nav_subtitle("Page validated.");
                $panel->content(sub { "<h3>No Errors on Page</h3>" });
            } else {
                $panel->nav_subtitle('Not valid. Error Count: '.$v->num_errors);
                my @errs = $self->parse_for_errors($v->_content());
                $panel->content(sub {
                    "<h3>Errors</h3>".
                    $self->render($table_template, \@errs);
                });
            }
        } else {
            $panel->content(sub {
                $self->render_lines([
                    "Failed to validate the website: ". $v->validator_error,
                ]);
            });
        }
    }
}

1;

=head1 NAME

Plack::Middleware::Debug::W3CValidate - Validate your Response Content

=head2 SYNOPSIS

    use Plack::Builder;

    my $app = ...; ## Build your Plack App

    builder {
        enable 'Debug', panels =>['W3CValidate'];
        $app;
    };

=head1 DESCRIPTION

Adds a debug panel that runs your response body through the W3C validator and
returns a list of errors.

=head1 OPTIONS

This debug panel defines the following options.

=head2 validator_uri

Takes the url of the W3C validator.  Defaults to the common validator, but if
you plan to pound this it would be polite to setup your own and point to that
instead.  Please see L<WebService::Validator::HTML::W3C> for more.

Since this panel needs to read and submit the response body to a POST service
it will definitely increase the time it takes to load the page.

=head1 SEE ALSO

L<Plack::Middleware::Debug>

=head1 AUTHOR

John Napiorkowski, C<< <jjnapiork@cpan.org> >>

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

