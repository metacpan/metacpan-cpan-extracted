package Net::Easypost::CustomsInfo;
$Net::Easypost::CustomsInfo::VERSION = '0.19';
use JSON::MaybeXS;
use Types::Standard qw(ArrayRef Bool Enum InstanceOf Str);

use Moo;
with qw/Net::Easypost::Resource/;
with qw/Net::Easypost::PostOnBuild/;
use namespace::autoclean;

has 'eel_ppc' => (
    is  => 'rw',
);

has 'contents_type' => (
    is  => 'rw',
    isa => Enum[qw/documents gift merchandise returned_goods sample other/]
);

has 'customs_certify' => (
    is  => 'rw',
    isa => Bool,
    coerce => sub { $_[0] ? JSON->true : JSON->false }
);

has 'non_delivery_option' => (
    is      => 'rw',
    isa     => Enum[qw/abandon return/],
    default => 'return'
);

has [qw/contents_explanation customs_signer/] => (
    is  => 'rw',
    isa => Str
    );

has 'restriction_type' => (
    is  => 'rw',
    isa => Enum[qw/none quarantine sanitary_phytosanitary_inspection/]
);

has 'restriction_comments' => (
    is  => 'rw',
    isa => Str
);

has 'customs_items' => (
    is  => 'rw',
    isa => ArrayRef[InstanceOf['Net::Easypost::CustomsItem']]
);

sub _build_fieldnames {
    return [
	qw/
	contents_explanation
	contents_type
	customs_certify
	customs_signer
	eel_ppc
	non_delivery_option
	restriction_comments
	restriction_type
	/
    ];
}
sub _build_role { 'customs_info' }
sub _build_operation { '/customs_infos' }

sub serialize {
   my ($self) = @_;

   my $obj = {
       map  { $self->role . "[$_]" => $self->$_ }
       grep { defined $self->$_ } @{ $self->fieldnames }
   };

   # if customs_items exist, they were already created in Net::Easypost::CustomsItem
   # so we can simply pass the id
   if ($self->customs_items) {
       foreach my $i (0 .. $#{ $self->customs_items }) {
	   my $item = $self->customs_items->[$i];
	   $obj->{$self->role . "[" . $item->role . "][$i][id]"} = $item->id;
       }
   }

   return $obj;
}

sub clone {
    my ($self) = @_;

    return Net::Easypost::CustomsInfo->new(
        map  { $_ => $self->$_ }
	grep { defined $self->$_ } @{ $self->fieldnames },
	'customs_items' => [
	    map { $_->clone } $self->customs_items
	]
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Easypost::CustomsInfo

=head1 VERSION

version 0.19

=head1 SYNOPSIS

 Net::Easypost::CustomsInfo->new

=head1 NAME

 Net::Easypost::CustomsInfo

=head1 ATTRIBUTES

=over 4

=item eel_pfc

 string: "EEL" or "PFC" value less than $2500: "NOEEI 30.37(a)"; value greater than $2500: see Customs Guide

=item contents_type

 string: "documents", "gift", "merchandise", "returned_goods", "sample", or "other"

=item contents_explanation

 string: Human readable description of content. Required for certain carriers and always required if contents_type is "other"

=item customs_certify

 boolean: Electronically certify the information provided

=item customs_signer

 string: Required if customs_certify is true

=item non_delivery_option

 string: "abandon" or "return", defaults to "return"

=item restriction_type

 string: "none", "other", "quarantine", or "sanitary_phytosanitary_inspection"

=item restriction_comments

 string: Required if restriction_type is not "none"

=item customs_items

 [L<Net::Easypost::CustomsItem>]: describes the products being shipped

=back

=head1 AUTHOR

Mark Allen <mrallen1@yahoo.com>, Hunter McMillen <mcmillhj@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Mark Allen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
