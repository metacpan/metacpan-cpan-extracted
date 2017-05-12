package Sub::Called;

use warnings;
use strict;

use B;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(with_ampersand already_called not_called);

=head1 NAME

Sub::Called - get information about how the subroutine is called

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS


    use Sub::Called;
    
    sub test {
        if( Sub::Called::with_ampersand() ){
            print "you called this subroutine this way: &test\n",
                  "note that this disables prototypes!\n";
        }
    }


    use Sub::Called 'already_called', 'not_called';
    
    sub user {
        unless (already_called) {   # only gets called once
            My::Fixtures::Users->load;
        }
        ...
    }
    
    sub schema {
        if ( not_called ) {
            # setup schema
        }
        else {
            return $schema;
        }
    }

=head1 EXPORTS

There are no subroutines exported by default, but you can export all subroutines
explicitly

  use Sub::Called qw(with_ampersand already_called not_called);

=head2 C<already_called>

This function must be called from inside a subroutine.  It will return false
if the subroutine has not yet been called.  It will only return false once.

This subroutine is only exported on demand.

=head2 C<not_called>

This function must be called from inside a subroutine.  It returns the
opposite value of C<already_called>.  Aside from this, there is no difference.
You may find aesthetically more pleasing.

This subroutine is only exported on demand.

=head2 C<with_ampersand>

This function must be called from inside a subroutine. It returns 1 if the subroutine
was called with an ampersand (e.g. C<&subroutine()>).

This subroutine is only exported on demand.

=head1 FUNCTIONS

=head2 C<with_ampersand>

=cut

sub with_ampersand {
    
    my $sub  = (caller(2))[3] || "main"; 
    my $line = (caller(1))[2];

    my $func = (caller(1))[3];
    
    my $svref = \&{$sub};
    my $obj   = B::svref_2object( $svref );
    
    my $op      = $sub eq 'main' ? B::main_start() : $obj->START;
    my $is_line = 0;
    my $retval  = 0;
    my $is_gv   = 0;

    my $test = B::main_cv;

    for(; $$op; $op = $op->next ){
        my $name    = $op->name;
        if( $name eq 'nextstate' ){
            $is_line = ( $op->line == $line );
        }
        elsif( $name eq 'gv' ){
           my $stash    = "";
           my $globname = "";

           if( B::class( $op ) eq 'PADOP' ){
               my $sv = (( $test->PADLIST->ARRAY)[1]->ARRAY)[ $op->padix ];
               if( $sv ){
                   my $class = B::class( $sv );
                   if( $class eq 'GV' ){
                       $stash    = $sv->STASH->NAME;
                       $globname = $sv->SAFENAME;
                   }
               }
           }
           else {
              $globname = $op->gv->NAME;
              $stash    = $op->gv->STASH->NAME; 
           }

           my $check = $stash . '::' . $globname;
           $is_gv    = 1 if $check eq $func;
        }
        
        next unless $is_line and $is_gv and $name eq 'entersub';
        
        my $priv = $op->private;

        my $key = 8;
        if( ( $key & $priv) == $key and $priv > $key ){
            $retval = 1;
        }
        last;
    }

    return $retval;
}

=head2 C<already_called>

=cut

my %called;

sub already_called() {
    my ( $package, $filename, $line, $subroutine ) = caller(1);
    my $called = $called{$package}{$subroutine};
    $called{$package}{$subroutine} = 1;
    return $called;
}

=head2 C<not_called>

=cut

sub not_called() {
    my ( $package, $filename, $line, $subroutine ) = caller(1);
    my $called = $called{$package}{$subroutine};
    $called{$package}{$subroutine} = 1;
    return not $called;
}

=head1 LIMITATIONS / TODO

There are limitations and I don't know if I can solve these "problems".
So this section is also named "TODO". If you know a solution for any
of these limitations, please let me know.

=head2 Subroutine References

It seems that there are some problems with subroutine references.

This may not work:

  sub test2 {
      if( Sub::Called::with_ampersand() ){
          die "die hard";
      }
  };
    
  my $sub2 = main->can( 'test2' );
  &$sub2();

=head2 Inside a module

If you call subroutines in a module but outside any subroutine (so
the subroutine calls are executed when the module is loaded), I cannot
give a correct answer ;-)

  package Check;
  
  use strict;
  use warnings;
  use Sub::Called qw(with_ampersand);
  
  &test;
  
  sub test {
      if( with_ampersand() ){
          print "yada yada yada\n";
      }
  }

=head1 AUTHOR

Renee Baecker, C<< <module at renee-baecker.de> >>

Curtis "Ovid" Poe, C<< <ovid at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-sub-called at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sub-Called>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sub::Called

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sub-Called>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Sub-Called>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sub-Called>

=item * Search CPAN

L<http://search.cpan.org/dist/Sub-Called>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 Renee Baecker, Curtis "Ovid" Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Sub::Called
