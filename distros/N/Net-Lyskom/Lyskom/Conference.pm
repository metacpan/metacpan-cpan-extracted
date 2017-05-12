package Net::Lyskom::Conference;
use base qw{Net::Lyskom::Object};
use strict;
use warnings;

use Net::Lyskom::Util qw{:all};
use Net::Lyskom::Time;
use Net::Lyskom::AuxItem;

=head1 NAME

Net::Lyskom::Conference - object that holds information on a conference

=head1 SYNOPSIS

  print "This conference is called ",$obj->name;


=head1 DESCRIPTION

All methods are read-only and take no arguments. Unless noted otherwise,
they return simple scalars.

=head2 Methods

=over

=item ->name()

=item ->creation_time()

  Returns a L<Net::Lyskom::Time> object;

=item ->last_written()

  Returns a L<Net::Lyskom::Time> object;

=item ->creator()

=item ->presentation()

=item ->supervisor()

=item ->permitted_submitters()

=item ->super_conf()

=item ->msg_of_day()

=item ->nice()

=item ->keep_commented()

=item ->no_of_members()

=item ->first_local_no()

=item ->no_of_texts()

=item ->expire()

=item ->aux_items()

  Returns a list of L<Net::Lyskom::AuxItem> objects.

=item ->rd_prot()

=item ->original()

=item ->secret()

=item ->letterbox()

=item ->allow_anonymous()

=item ->forbid_secret()

=item ->highest_local_no()

=back

=cut

# Accessors

sub name {my $s = shift; return $s->{name}}
sub creation_time {my $s = shift; return $s->{creation_time}}
sub last_written {my $s = shift; return $s->{last_written}}
sub creator {my $s = shift; return $s->{creator}}
sub presentation {my $s = shift; return $s->{presentation}}
sub supervisor {my $s = shift; return $s->{supervisor}}
sub permitted_submitters {my $s = shift; return $s->{permitted_submitters}}
sub super_conf {my $s = shift; return $s->{super_conf}}
sub msg_of_day {my $s = shift; return $s->{msg_of_day}}
sub nice {my $s = shift; return $s->{nice}}
sub keep_commented {my $s = shift; return $s->{keep_commented}}
sub no_of_members {my $s = shift; return $s->{no_of_members}}
sub first_local_no {my $s = shift; return $s->{first_local_no}}
sub no_of_texts {my $s = shift; return $s->{no_of_texts}}
sub expire {my $s = shift; return $s->{expire}}
sub aux_items {my $s = shift; return @{$s->{aux_items}}}

sub rd_prot {my $s = shift; return $s->{rd_prot}}
sub original {my $s = shift; return $s->{original}}
sub secret {my $s = shift; return $s->{secret}}
sub letterbox {my $s = shift; return $s->{letterbox}}
sub allow_anonymous {my $s = shift; return $s->{allow_anonymous}}
sub forbid_secret {my $s = shift; return $s->{forbid_secret}}
sub highest_local_no {my $s = shift; return $s->{highest_local_no}}

sub new_from_stream {
    my $s = {};
    my $class = shift;

    $class = ref($class) if ref($class);
    bless $s,$class;

    $s->{name} = shift @{$_[0]};
    my $type = shift @{$_[0]};
    $s->{creation_time} = Net::Lyskom::Time->new_from_stream($_[0]);
    $s->{last_written} = Net::Lyskom::Time->new_from_stream($_[0]);
    $s->{creator} = shift @{$_[0]};
    $s->{presentation} = shift @{$_[0]};
    $s->{supervisor} = shift @{$_[0]};
    $s->{permitted_submitters} = shift @{$_[0]};
    $s->{super_conf} = shift @{$_[0]};
    $s->{msg_of_day} = shift @{$_[0]};
    $s->{nice} = shift @{$_[0]};
    $s->{keep_commented} = shift @{$_[0]};
    $s->{no_of_members} = shift @{$_[0]};
    $s->{first_local_no} = shift @{$_[0]};
    $s->{no_of_texts} = shift @{$_[0]};
    $s->{expire} = shift @{$_[0]};
    $s->{aux_items} = [parse_array_stream(sub{Net::Lyskom::AuxItem->new_from_stream(@_)},$_[0])];

    my ($rd_prot,
	$original,
	$secret,
	$letterbox,
	$allow_anonymous,
	$forbid_secret,
	undef,
	undef) = $type =~ /./g;
    $s->{rd_prot} = $rd_prot == 1;
    $s->{original} = $original == 1;
    $s->{secret} = $secret == 1;
    $s->{letterbox} = $letterbox == 1;
    $s->{allow_anonymous} = $allow_anonymous == 1;
    $s->{forbid_secret} = $forbid_secret == 1;

    return $s;
}

sub new_from_ustream {
    my $s = {};
    my $class = shift;

    $class = ref($class) if ref($class);
    bless $s,$class;

    $s->{name} = shift @{$_[0]};
    my $type = shift @{$_[0]};
    $s->{highest_local_no} = shift @{$_[0]};
    $s->{nice} = shift @{$_[0]};

    my ($rd_prot,
	$original,
	$secret,
	$letterbox,
	$allow_anonymous,
	$forbid_secret ) = $type =~ /./g;
    $s->{rd_prot} = $rd_prot == 1;
    $s->{original} = $original == 1;
    $s->{secret} = $secret == 1;
    $s->{letterbox} = $letterbox == 1;
    $s->{allow_anonymous} = $allow_anonymous == 1;
    $s->{forbid_secret} = $forbid_secret == 1;

    return $s;
}

1;
