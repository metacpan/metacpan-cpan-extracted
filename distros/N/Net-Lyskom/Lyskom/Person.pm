package Net::Lyskom::Person;
use base qw{Net::Lyskom::Object};
use strict;
use warnings;

use Net::Lyskom::Util qw{:all};
use Net::Lyskom::Time;

=head1 NAME

Net::Lyskom::Person - object holding status for a person

=head1 SYNOPSIS

  print "This user has written ",$obj->created_bytes/1024," kilobytes of texts.";


=head1 DESCRIPTION

All methods in this object are read-only and take no arguments. Unless
noted otherwise, all methods return simple scalars.

=head2 Methods

=over

=item ->username()

=item ->last_login()

  Returns L<Net::Lyskom::Time> object;

=item ->user_area()

=item ->total_time_present()

=item ->sessions()

=item ->created_lines()

=item ->created_bytes()

=item ->read_texts()

=item ->no_of_text_fetches()

=item ->created_persons()

=item ->created_confs()

=item ->first_created_local()

=item ->no_of_created_texts()

=item ->no_of_marks()

=item ->no_of_confs()

=item ->wheel()

=item ->admin()

=item ->statistic()

=item ->create_pers()

=item ->create_conf()

=item ->change_name()

=item ->unread_is_secret()

=back

=cut

# Accessors
sub username {my $s = shift; return $s->{username}}
sub last_login {my $s = shift; return $s->{last_login}}
sub user_area {my $s = shift; return $s->{user_area}}
sub total_time_present {my $s = shift; return $s->{total_time_present}}
sub sessions {my $s = shift; return $s->{sessions}}
sub created_lines {my $s = shift; return $s->{created_lines}}
sub created_bytes {my $s = shift; return $s->{created_bytes}}
sub read_texts {my $s = shift; return $s->{read_texts}}
sub no_of_text_fetches {my $s = shift; return $s->{no_of_text_fetches}}
sub created_persons {my $s = shift; return $s->{created_persons}}
sub created_confs {my $s = shift; return $s->{created_confs}}
sub first_created_local_no {my $s = shift; return $s->{first_created_local_no}}
sub no_of_created_texts {my $s = shift; return $s->{no_of_created_texts}}
sub no_of_marks {my $s = shift; return $s->{no_of_marks}}
sub no_of_confs {my $s = shift; return $s->{no_of_confs}}

# Flags
sub unread_is_secret {my $s = shift; return $s->{unread_is_secret}}

# Privs
sub wheel {my $s = shift; return $s->{wheel}}
sub admin {my $s = shift; return $s->{admin}}
sub statistic {my $s = shift; return $s->{statistic}}
sub create_pers {my $s = shift; return $s->{create_pers}}
sub create_conf {my $s = shift; return $s->{create_conf}}
sub change_name {my $s = shift; return $s->{change_name}}

sub new_from_stream {
    my $s = {};
    my $class = shift;
    my $ref = shift;

    $class = ref($class) if ref($class);
    bless $s,$class;

    $s->{username} = shift @{$ref};
    my $privs = shift @{$ref};
    my $flags = shift @{$ref};
    $s->{last_login} = Net::Lyskom::Time->new_from_stream($ref);
    $s->{user_area} = shift @{$ref};
    $s->{total_time_present} = shift @{$ref};
    $s->{sessions} = shift @{$ref};
    $s->{created_lines} = shift @{$ref};
    $s->{created_bytes} = shift @{$ref};
    $s->{read_texts} = shift @{$ref};
    $s->{no_of_text_fetches} = shift @{$ref};
    $s->{created_persons} = shift @{$ref};
    $s->{created_confs} = shift @{$ref};
    $s->{first_created_local} = shift @{$ref};
    $s->{no_of_created_texts} = shift @{$ref};
    $s->{no_of_marks} = shift @{$ref};
    $s->{no_of_confs} = shift @{$ref};

    (
     $s->{wheel},
     $s->{admin},
     $s->{statistic},
     $s->{create_pers},
     $s->{create_conf},
     $s->{change_name},
    ) = $privs =~ /./g;

    (
     $s->{unread_is_secret}
    ) = $flags =~ /./g;

    return $s;
}

1;
