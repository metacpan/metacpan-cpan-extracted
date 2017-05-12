package Net::Lyskom::ConfZInfo;
use base qw{Net::Lyskom::Object};
use strict;
use warnings;

use Net::Lyskom::Util qw{:all};

=head1 NAME

Net::Lyskom::ConfZInfo - conf_z_info object

=head1 SYNOPSIS

  print $obj->name, " is a mailbox." if $obj->letterbox;

=head1 DESCRIPTION

All methods are read-only and return simple scalars.

=head2 Methods

=over

=item ->name()

=item ->conf_no()

=item ->rd_prot()

=item ->original()

=item ->secret()

=item ->letterbox()

=back



=cut

sub name {my $s = shift; return $s->{name}}
sub conf_no {my $s = shift; return $s->{conf_no}}

sub rd_prot {my $s = shift; return $s->{rd_prot}}
sub original {my $s = shift; return $s->{original}}
sub secret {my $s = shift; return $s->{secret}}
sub letterbox {my $s = shift; return $s->{letterbox}}

sub new_from_stream {
    my $s = {};
    my $class = shift;
    my $ref = shift;

    $class = ref($class) if ref($class);
    bless $s,$class;

    $s->{name} = shift @{$ref};
    my $type = shift @{$ref};
    $s->{conf_no} = shift @{$ref};
    ($s->{rd_prot},$s->{original},$s->{secret},$s->{letterbox})
      = $type =~ /./g;

    return $s;
}

1;
