package Net::Akamai::RequestData::Types;

use Moose;
use SOAP::Lite;
use Moose::Util::TypeConstraints;

=head1 NAME
    
Net::Akamai::RequestData::Types - Define request data types for coercion 
    
=head1 DESCRIPTION

Data type definitions 

=cut

=head1 Types 

=head2 Net::Akamai::RequestData::Types::PurgeOptions 

SOAP::Data object

=cut
subtype 'Net::Akamai::RequestData::Types::PurgeOptions'
	=> as 'Object'
	=> where { $_->isa('SOAP::Data') };

=head2 Net::Akamai::RequestData::Types::PurgeOptionsArrayRef 

ArrayRef of Net::Akamai::RequestData::Types::PurgeOptions

=cut
subtype 'Net::Akamai::RequestData::Types::PurgeOptionsArrayRef'
	=> as 'ArrayRef[Net::Akamai::RequestData::Types::PurgeOptions]';

coerce 'Net::Akamai::RequestData::Types::PurgeOptionsArrayRef'
	=> from 'ArrayRef[Str]'
	=> via { [map {SOAP::Data->type('string')->value("$_")} @$_] };

=head2 Net::Akamai::RequestData::Types::PurgeAction 

invalidate or remove

=cut
enum 'Net::Akamai::RequestData::Types::PurgeAction'
    => [qw(invalidate remove)];

=head2 Net::Akamai::RequestData::Types::PurgeType 

cpcode or arl

=cut
enum 'Net::Akamai::RequestData::Types::PurgeType' => [qw(cpcode arl)];

=head1 AUTHOR

John Goulah  <jgoulah@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
