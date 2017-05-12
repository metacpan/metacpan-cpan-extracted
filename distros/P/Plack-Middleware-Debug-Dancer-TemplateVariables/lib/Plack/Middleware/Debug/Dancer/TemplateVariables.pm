package Plack::Middleware::Debug::Dancer::TemplateVariables;
{
  $Plack::Middleware::Debug::Dancer::TemplateVariables::VERSION = '0.002';
}
# ABSTRACT: Debug and inspect your template variables for Dancer

use strict;
use warnings;
use parent qw(Plack::Middleware::Debug::Base);

use Dancer;
use Data::Dumper ();

my $env_key = 'debug.dancer.templatevariables';

sub prepare_app {
    Dancer::Hook->new('before_layout_render' => sub {
        my $tokens = shift;
        Dancer::SharedData->request->env->{$env_key} = $tokens;
    });
}

my $list_template_dumped = __PACKAGE__->build_template(<<'EOTMPL');
<table>
    <thead>
        <tr>
            <th>Key</th>
            <th>Value</th>
        </tr>
    </thead>
    <tbody>
% my $i;
% while (@{$_[0]->{list}}) {
% my($key, $value) = splice(@{$_[0]->{list}}, 0, 2);
            <tr class="<%= ++$i % 2 ? 'plDebugOdd' : 'plDebugEven' %>">
                <td><%= $key %></td>
                <td><pre><%= vardump($value) %></pre></td>
            </tr>
% }
    </tbody>
</table>
EOTMPL

sub vardump {
    my $scalar = shift;
    return '(undef)' unless defined $scalar;
    return "$scalar" unless ref $scalar;
    scalar Data::Dump::dump($scalar);
}

sub run {
    my ( $self, $env, $panel ) = @_;
 
    return sub {
        my $res = shift;
        $panel->title('Dancer::TemplateVariables');
        $panel->nav_subtitle('Dancer::TemplateVariables');
        $panel->content( sub {
            my %vars = %{ $env->{$env_key} || {} };
            my @var_list = map { $_ => $vars{$_} } sort keys %vars;
            $self->render( $list_template_dumped, { list => \@var_list } );
        } );
    };
}

1;


__END__
=pod

=head1 NAME

Plack::Middleware::Debug::Dancer::TemplateVariables - Debug and inspect your template variables for Dancer

=head1 VERSION

version 0.002

=head1 SYNOPSIS

To activate this panel:

    plack_middlewares:
      Debug:
        - panels
        -
          - Dancer::TemplateVariables

Or by manually creating an app.psgi, that might contain:

    builder {
        enable 'Debug', panels => ['Dancer::TemplateVariables'];
        $app;
    };

Note, that no 'use Plack::Middleware::Debug::Dancer::TemplateVariables' is
needed.

=head1 DESCRIPTION

This middleware simply dumps all of the variables, that are passed by
Dancer through the template directive. This is achieved by installing a
before_layout_render-hook, that saves $tokens for later display.

=head1 CAVEATS

Everything is mostly untested. Although it worked in conjunction with
L<Template::Toolkit> when manually testing it.

=head1 INSPIRATION

The Idea of Dumping all Template Variables came from
L<Plack::Middleware::Debug::TemplateToolkit> which only seems to work in
companion with L<Plack::Middleware::TemplateToolkit>.

Some parts of the code are stolen from L<Plack::Middleware::Debug::Base>. Most
notably the vardump-sub. The list-template is also copied, because I wanted to
add a simple pre-tag around the dumped variable, which creates a better format.

=cut

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AUTHOR

Thomas Müller <tmueller@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Thomas Müller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

