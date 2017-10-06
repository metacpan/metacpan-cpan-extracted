
package Mojo::Bass;
$Mojo::Bass::VERSION = '0.1.1';
# ABSTRACT: Mojo::Base + lexical "has"
use 5.018;
use Mojo::Base -strict;

BEGIN {
  our @ISA = qw(Mojo::Base);
}

use Sub::Inject 0.2.0 ();

sub import {
  my $class = shift;
  return unless my $flag = shift;

  # Base
  if ($flag eq '-base') { $flag = $class }

  # Strict
  elsif ($flag eq '-strict') { $flag = undef }

  # Module
  elsif ((my $file = $flag) && !$flag->can('new')) {
    $file =~ s!::|'!/!g;
    require "$file.pm";
  }

  # Mojo modules are strict!
  $_->import for qw(strict warnings utf8);
  feature->import(':5.10');

  # ISA
  if ($flag) {
    my $caller = caller;
    no strict 'refs';
    push @{"${caller}::ISA"}, $flag;
    @_ = ($caller, has => sub { Mojo::Base::attr($caller, @_) });
    goto &{$class->can('_export_into')};
  }
}

sub _export_into {
  shift;
  goto &Sub::Inject::sub_inject;
}

1;

#pod =encoding utf8
#pod
#pod =head1 SYNOPSIS
#pod
#pod   package Cat {
#pod     use Mojo::Bass -base;
#pod
#pod     has name => 'Nyan';
#pod     has ['age', 'weight'] => 4;
#pod   }
#pod
#pod   package Tiger {
#pod     use Mojo::Bass 'Cat';
#pod
#pod     has friend => sub { Cat->new };
#pod     has stripes => 42;
#pod   }
#pod
#pod   package main;
#pod   use Mojo::Bass -strict;
#pod
#pod   my $mew = Cat->new(name => 'Longcat');
#pod   say $mew->age;
#pod   say $mew->age(3)->weight(5)->age;
#pod
#pod   my $rawr = Tiger->new(stripes => 38, weight => 250);
#pod   say $rawr->tap(sub { $_->friend->name('Tacgnol') })->weight;
#pod
#pod =head1 DESCRIPTION
#pod
#pod L<Mojo::Bass> works like L<Mojo::Base> but C<has> is imported
#pod as lexical subroutine.
#pod
#pod =head1 CAVEATS
#pod
#pod =over 4
#pod
#pod =item *
#pod
#pod L<Mojo::Bass> requires perl 5.18 or newer
#pod
#pod =item *
#pod
#pod Because a lexical sub does not behave like a package import,
#pod some code may need to be enclosed in blocks to avoid warnings like
#pod
#pod     "state" subroutine &has masks earlier declaration in same scope at...
#pod
#pod =back
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Mojo::Base>.
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojo::Bass - Mojo::Base + lexical "has"

=head1 VERSION

version 0.1.1

=head1 SYNOPSIS

  package Cat {
    use Mojo::Bass -base;

    has name => 'Nyan';
    has ['age', 'weight'] => 4;
  }

  package Tiger {
    use Mojo::Bass 'Cat';

    has friend => sub { Cat->new };
    has stripes => 42;
  }

  package main;
  use Mojo::Bass -strict;

  my $mew = Cat->new(name => 'Longcat');
  say $mew->age;
  say $mew->age(3)->weight(5)->age;

  my $rawr = Tiger->new(stripes => 38, weight => 250);
  say $rawr->tap(sub { $_->friend->name('Tacgnol') })->weight;

=head1 DESCRIPTION

L<Mojo::Bass> works like L<Mojo::Base> but C<has> is imported
as lexical subroutine.

=head1 CAVEATS

=over 4

=item *

L<Mojo::Bass> requires perl 5.18 or newer

=item *

Because a lexical sub does not behave like a package import,
some code may need to be enclosed in blocks to avoid warnings like

    "state" subroutine &has masks earlier declaration in same scope at...

=back

=head1 SEE ALSO

L<Mojo::Base>.

=head1 AUTHOR

Adriano Ferreira <ferreira@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Adriano Ferreira.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
