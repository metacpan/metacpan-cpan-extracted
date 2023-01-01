use 5.14.0;
package Router::Dumb::Helper::RouteFile 0.006;
use Moose;
# ABSTRACT: something to read routes out of a dumb text file

#pod =head1 OVERVIEW
#pod
#pod   my $r = Router::Dumb->new;
#pod   
#pod   Router::Dumb::Helper::RouteFile->new({ filename => 'routes.txt' })
#pod                                  ->add_routes_to( $r );
#pod
#pod ...and F<routes.txt> looks like...
#pod
#pod   # These are some great routes!
#pod
#pod   /citizen/:num/dob  =>  /citizen/dob
#pod     num isa Int
#pod
#pod   /blog/*            =>  /blog
#pod
#pod Then routes are added, doing just what you'd expect.  This helper is pretty
#pod dumb, but the whole Router::Dumb system is, too.
#pod
#pod =cut

use Router::Dumb::Route;

use Moose::Util::TypeConstraints qw(find_type_constraint);

use namespace::autoclean;

has filename => (is => 'ro', isa => 'Str', required => 1);

sub add_routes_to {
  my ($self, $router, $arg) = @_;
  $arg ||= {};

  my $file = $self->filename;

  my @lines;
  {
    open my $fh, '<', $file or die "can't open $file for reading: $!";

    # ignore comments, blanks
    @lines = grep { /\S/ }
             map  { chomp; s/#.*\z//r } <$fh>
  }

  my $add_method = $arg->{ignore_conflicts}
                 ? 'add_route_unless_exists'
                 : 'add_route';

  my $curr;
  for my $i (0 .. $#lines) {
    my $line = $lines[$i];

    if ($line =~ /^\s/) {
      confess "indented line found out of context of a route" unless $curr;
      confess "couldn't understand line <$line>"
        unless my ($name, $type) = $line =~ /\A\s+(\S+)\s+isa\s+(\S+)\s*\z/;

      $curr->{constraints}->{$name} = find_type_constraint($type);
    } else {
      my ($path, $target) = split /\s*=>\s*/, $line;
      s{^/}{} for $path, $target;
      my @parts = split m{/}, $path;

      $curr = {
        parts  => \@parts,
        target => $target,
      };
    }

    if ($curr and ($i == $#lines or $lines[ $i + 1 ] =~ /^\S/)) {
      $router->$add_method( Router::Dumb::Route->new($curr) );
      undef $curr;
    }
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Router::Dumb::Helper::RouteFile - something to read routes out of a dumb text file

=head1 VERSION

version 0.006

=head1 OVERVIEW

  my $r = Router::Dumb->new;
  
  Router::Dumb::Helper::RouteFile->new({ filename => 'routes.txt' })
                                 ->add_routes_to( $r );

...and F<routes.txt> looks like...

  # These are some great routes!

  /citizen/:num/dob  =>  /citizen/dob
    num isa Int

  /blog/*            =>  /blog

Then routes are added, doing just what you'd expect.  This helper is pretty
dumb, but the whole Router::Dumb system is, too.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
