package Populous;
BEGIN {
  $Populous::AUTHORITY = 'cpan:GETTY';
}
{
  $Populous::VERSION = '0.001';
}
# ABSTRACT: Populate anything like a god

use Moo;
use Package::Stash;

has classes => (
  is => 'ro',
  required => 1,
);

has cache => (
  is => 'ro',
  lazy => 1,
  builder => sub {{}},
);

has package_namespace => (
  is => 'ro',
  lazy => 1,
  builder => sub {
    my ( $self ) = @_;
    my $class_id = "$self";
    $class_id =~ s/[^\w\d]//g;
    return "__POPULOUS_GENERATED_$class_id";
  },
);

sub class_to_package {
  my ( $self, $class ) = @_;
  return join("::",$self->package_namespace,$class);
}

sub BUILD {
  my ( $self ) = @_;
  my @classes = @{$self->classes};
  my $stash = Package::Stash->new(ref $self);
  while (@classes) {
    my $class = shift @classes;
    my $constructor = shift @classes;
    my %functions;
    if (ref $classes[0] eq 'HASH') {
      my $functions_ref = shift @classes;
      %functions = %{$functions_ref};
    }
    my $package = $self->class_to_package($class);
    $stash->add_symbol('&new_'.$class,sub {
      shift;
      my $i = 0;
      while (@_) {
        my $id = shift;
        my $arg = shift;
        my $object = $constructor->($id,$arg);
        $self->cache->{$class}->{$id} = bless [ $object, $id ], $package;
        $i++;
      }
      return $i;
    });
    $stash->add_symbol('&delete_'.$class,sub {
      shift;
      my @killed;
      for (@_) {
        push @killed, (delete $self->cache->{$class}->{$_});
      }
      return @killed;
    });
    $stash->add_symbol('&get_'.$class,sub {
      shift;
      if (wantarray) {
        my @return;
        for (@_) {
          push @return, $self->cache->{$class}->{$_}->[0];
        }
        return @return;
      } else {
        return $self->cache->{$class}->{$_[0]}->[0];
      }
    });
    $stash->add_symbol('&'.$class,sub {
      shift;
      my ( $id, $func, @args ) = @_;
      return unless defined $self->cache->{$class}->{$id};
      my $object = $self->cache->{$class}->{$id};
      return $object unless defined $func;
      return $object->$func(@args);
    });
    $functions{delete} = sub {
      delete $self->cache->{$class}->{$_->[1]};
    };
    $self->create_package($package, %functions);
  }
}

sub create_package {
  my ( $self, $package, %functions ) = @_;
  my $stash = Package::Stash->new($package);
  for my $function_name (keys %functions) {
    $stash->add_symbol('&'.$function_name,sub {
      my $self_ref = shift;
      my $self = $self_ref->[0];
      for ($self_ref) {
        return $functions{$function_name}->($self,@_);
      }
    });
  }
}

1;

__END__

=pod

=head1 NAME

Populous - Populate anything like a god

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $p = Populous->new(
    classes => [
      user => sub { 'User '.(shift).' called '.(shift) }, {
        does => sub { (shift).' does '.(shift) },
      },
      other => sub { 'Other '.(shift) },
    ],
  );

  $p->new_user(
    a => "Abraham",
    b => "Betleham",
  );

  print $p->user( a => does => 'stuff');
  # 'User a called Abraham does stuff'
  $p->user("b")->does('otherstuff');
  # 'User b called Betleham does otherstuff'

=encoding utf8

=head1 SUPPORT

IRC

  Join #perl-help on irc.perl.org. Highlight Getty for fast reaction :).

Repository

  http://github.com/Getty/p5-populous
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-populous/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
