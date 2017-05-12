#    Copyright (c) 2011 Raphael Pinson.
#
#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser Public License as
#    published by the Free Software Foundation; either version 2.1 of
#    the License, or (at your option) any later version.
#
#    Config-Model is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser Public License for more details.
#
#    You should have received a copy of the GNU Lesser Public License
#    along with Config-Model; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
#    02110-1301 USA

package Reprepro::Uploaders;

use strict;
use warnings;
use base qw(Class::Accessor);
use Config::Augeas qw(get match);
use Text::Glob qw(match_glob);

our $VERSION = '0.004';

my %conditions_types = (
   'source' 			=> \&check_source,
   'byhand' 			=> \&check_byhand,
   'sections' 			=> \&check_items,
   'binaries' 			=> \&check_items,
   'architectures'   => \&check_items,
);

sub new {
   my $class = shift;
   my %options = @_;

   my $self = __PACKAGE__->SUPER::new();

   $self->{uploaders} = $options{uploaders};
   die "E: You must provide an uploders file" unless $self->{uploaders};

   $self->{debug} = $options{debug};
   $self->{verbose} = $self->{debug};
   $self->{verbose} ||= $options{verbose};

   $self->{augeas_opts} = $options{augeas_opts};
   $self->setup_augeas();

   return $self;
}

sub setup_augeas {
   my ($self) = @_;

   $self->{augeas_opts}->{no_load} = 1;

   my $aug = Config::Augeas->new(%{$self->{augeas_opts}});
   $aug->rm("/augeas/load/*");
   $aug->set("/augeas/load/Reprepro_Uploaders/lens", "Reprepro_Uploaders.lns");
   $aug->set("/augeas/load/Reprepro_Uploaders/incl", $self->{uploaders});
   $aug->load();
   $aug->match("/augeas/files//error") && die "E: Parsing failed";

   $self->{aug} = $aug;
}

sub check_package {
   my ($self, $package) = @_;

   my $key = $package->{'key'};

   my $key_condition  = "by/key = '$key' or by/key = 'any'";
      $key_condition .= " or by = 'anybody' or by = 'unsigned'";

   my $key_path = "/files/$self->{uploaders}/allow[$key_condition]";

   $self->{package} = $package;
   @{$self->{errors}} = ();

   my @allows = $self->{aug}->match($key_path);

   if ($#allows < 0) {
      push @{$self->{errors}}, "Unknown key $key";
      return 0;
   }

   foreach my $allow (@allows) {
      return 1 if ($self->check_allow($allow));
   }

   return 0;
}

sub check_allow {
   my ($self, $allow) = @_;

   my $aug = $self->{aug};
   my $package = $self->{package};

   print "V: Checking against $allow:",$/ if $self->{verbose};
   print $aug->print($allow).$/ if $self->{debug};
   
   my $allow_val = $aug->get($allow);
   if ($allow_val && $allow_val eq '*') {
      print "V: Wildcard found".$/ if $self->{verbose};
      return 1;
   }

   if ($self->check_condition_list($allow)) {
      return 1;
   }

   return 0;
}

sub check_condition_list {
   my ($self, $allow) = @_;

   my $aug = $self->{aug};
   my $package = $self->{package};

   my @conditions = $aug->match("$allow/and");

   foreach my $condition (@conditions) {
      return 0 unless ($self->check_condition($condition));
   }

   return 1;
}

sub check_condition {
   my ($self, $condition) = @_;

   my $aug = $self->{aug};
   my $package = $self->{package};

   my @conditions_or = $aug->match("$condition/or");

   my $not;

   foreach my $condition_or (@conditions_or) {
      my $condition_type = $aug->get($condition_or);

      die "E: Unknown condition type $condition_type\n"
         unless (defined $conditions_types{$condition_type});

      # A 'not' node invets the condition
      $not = ($aug->match("$condition_or/not")) ? 1 : 0;

      if ($conditions_types{$condition_type}($self, $condition_or, $condition_type)) {
         return 1-$not;
      }
   }

   return $not;
}


sub check_source {
   my ($self, $condition, $field) = @_;

   my $aug = $self->{aug};
   my $package = $self->{package};

   my $source = $package->{source};
   my $value = $aug->get("$condition/or");

   if (match_glob($value, $source)) {
      print "V: $field $source matches $value",$/ if $self->{verbose};
      return 1;
   } else {
      print "V: $field $source does not match $value",$/ if $self->{verbose};
      push @{$self->{errors}}, "$field $source does not match $value";
      return 0;
   }
}

sub check_byhand {
   my ($self, $condition) = @_;

   # TO BE IMPLEMENTED
}

sub check_items {
   my ($self, $condition, $field) = @_;

   my $aug = $self->{aug};
   my $package = $self->{package};

   # A 'contain' node makes the test valid if only one item is valid
   my $contain = 0;
   $contain = 1 if ($aug->match("$condition/contain"));

   my $accepted = -1;
   my @items = @{$package->{$field}};

   my $field_singular = $field;
   $field_singular =~ s|s$||;

   ITEM: foreach my $item (@items) {
      foreach my $value_n ($aug->match("$condition/or")) {
         my $value = $aug->get($value_n);
         if (match_glob($value, $item)) {
            return 1 if ($contain);
            $accepted++;
            print "V: $field_singular $item matches $value",$/ if $self->{verbose};
            next ITEM;
         } else {
            print "V: $field_singular $item does not match $value",$/ if $self->{verbose};
            push @{$self->{errors}}, "$field_singular $item does not match $value";
         }
      }
   }

   return ($accepted == $#items);
}

1;


__END__


=head1 NAME

   Reprepro::Uploaders - Emulates reprepro's upload permissions

=head1 SYNOPSIS

   use Reprepro::Uploaders;

   # Initialize
   my $uploaders = Reprepro::Uploaders->new(
      uploaders   => "/etc/reprepro/uploaders",  # Mandatory, no default
      verbose     => 1,                          # Or debug for more messages
      augeas_opts => {                           # Setup Config::Augeas
         root     => "/var/lib/fakeroot",
      },
   );

   my %package = (
      source         => 'libfoo-bar-perl',
      binaries       => [ 'libfoo-bar-perl' ],
      key            => 'ABCD1234',
      architectures  => [ 'source' ],
      sections       => [ 'main/perl' ],
   );

   print "Package accepted".$/ if ($uploaders->check_package(\%package));


=head1 SEE ALSO

L<Config::Augeas>


=cut

