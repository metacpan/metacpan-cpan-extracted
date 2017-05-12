use strict;

package Net::Moo::Validate;
use base qw (LWP::UserAgent);

$Net::Moo::Validate::VERSION = '0.11';

=head1 NAME 

Net::Moo::Document - object methods to validate  XML documents for the Moo API.

=head1 SYNOPSIS

 There is no SYNOPSIS. Consult Net::Moo for details.

=head1 DESCRIPTION

Object methods to validate XML documents for the Moo API.

=cut

use HTTP::Request;
use Data::Dumper;

sub report {
        my $self = shift;
        my $xml = shift;

        return $self->_validate($xml);
}

sub report_errors {
        my $self = shift;
        my $xml = shift;

        my $report = $self->_validate($xml);
        my %errors = ();

        foreach my $fail ('invalid xml', 'must be resolved'){

                if (exists($report->{$fail})){
                        $errors{$fail} = $report->{$fail};
                }
        }

        return (scalar(keys %errors)) ? \%errors : undef;
}

sub is_valid_xml {
        my $self = shift;
        my $report = shift;

        foreach my $fail ('invalid xml', 'must be resolved'){

                if (exists($report->{$fail})){
                        return 0;
                }
        }

        return 1;
}

sub _validate {
        my $self = shift;
        my $xml = shift;

        my $req = HTTP::Request->new('POST' => 'http://www.moo.com/api/api.php');
        $req->content_type('application/x-www-form-urlencoded'); 
        $req->content("dev=1&xml=" . $xml);
        
        my $res = $self->request($req);

        my $parser = Net::Moo::Validator->new();
        return $parser->parse($res->content());
}

package Net::Moo::Validator;
use base qw (HTML::Parser);

use HTML::Entities qw(decode_entities);

sub new {
        my $pkg = shift;
        
        my $self = $pkg->SUPER::new( api_version => 3,
                                     start_h => [\&_start, "self, tagname, attr"],
                                     end_h   => [\&_end,   "self, tagname"],
                                     text_h   => [\&_text,   "self, text"],
                                   );

        $self->{'__active'} = 0;
        $self->{'__capture'} = undef;
        $self->{'__invalid'} = 0;
        $self->{'__report'} = {};

        return bless $self, $pkg;
}

sub parse {
        my $self = shift;
        my $text = shift;

        $self->utf8_mode(1);
        $self->SUPER::parse($text);
        return $self->{'__report'};
}

sub _start {
        my $self = shift;
        my $tag = shift;
        my $attrs = shift;

        if ($tag ne 'div'){
                return 0;
        }

        if ((! exists($attrs->{'class'})) || ($attrs->{'class'} ne 'contentfull')){
                return;
        }

        $self->{'__active'} = 1;
        return 1;
}

sub _end {
        my $self = shift;
        my $tag = shift;

        if (($tag eq 'div') && ($self->{'__active'})){
                $self->{'__active'} = 0;                
                return 1;
        }

        if (($tag eq 'pre') && ($self->{'__active'})){
                $self->{'__capture'} = undef;
                $self->{'__invalid'} = 0;
        }

        if (($tag eq "ul") && ($self->{'__active'}) && (! $self->{'__invalid'})){
                $self->{'__capture'} = undef;
        }

        return 0;
}

sub _text {
        my $self = shift;
        my $text = shift;

        if (! $self->{'__active'}){
                return 0;
        }

        if ($text =~ /Things that (.*):/){
                $self->{'__capture'} = $1;
                return 1;
        }

        if ($text =~ /XML is not valid/){
                $self->{'__capture'} = 'invalid xml';
                $self->{'__invalid'} = 1;
                return 1;
        }
        
        if (! $self->{'__capture'}){
                return 0;
        }
            
        if ($text !~ /\w/){
                return 0;
        }

        my $key = $self->{'__capture'};
        $self->{'__report'}->{$key} ||= [];
        
        if ($self->{'__invalid'}){
                $text = decode_entities($text);
        }

        push @{$self->{'__report'}->{$key}}, $text;
        return 1;
    }

=head1 VERSION

0.11

=head1 DATE

$Date: 2008/06/19 15:15:34 $

=head1 AUTHOR

Aaron Straup Cope E<lt>ascope@cpan.orgE<gt>

=head1 SEE ALSO

L<Net::Moo>

=head1 LICENSE

Copyright (c) 2008 Aaron Straup Cope. All rights reserved.

This is free software. You may redistribute it and/or
modify it under the same terms as Perl itself.

return 1;
