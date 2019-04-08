package Sub::Called;

# ABSTRACT: get information about how the subroutine is called

use warnings;
use strict;

use B;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(with_ampersand already_called not_called);

our $VERSION = '0.05';


sub with_ampersand {
    
    my $sub  = (caller(2))[3] || "main"; 
    my $line = (caller(1))[2];

    my $func = (caller(1))[3];
    
    my $svref = \&{$sub};
    my $obj   = B::svref_2object( $svref );

use Data::Printer;
p $obj;
p @{[  $sub, $line, $func ]};
p @{[ caller(2) ]};
p @{[ caller(1) ]};
    
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


my %called;

sub already_called() {
    my ( $package, $filename, $line, $subroutine ) = caller(1);
    my $called = $called{$package}{$subroutine};
    $called{$package}{$subroutine} = 1;
    return $called;
}


sub not_called() {
    my ( $package, $filename, $line, $subroutine ) = caller(1);
    my $called = $called{$package}{$subroutine};
    $called{$package}{$subroutine} = 1;
    return not $called;
}


1; # End of Sub::Called

__END__

=pod

=encoding UTF-8

=head1 NAME

Sub::Called - get information about how the subroutine is called

=head1 VERSION

version 0.05

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

=head2 C<already_called>

=head2 C<not_called>

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

=head1 CONTRIBUTORS

Renee Baecker, C<< <module at renee-baecker.de> >>

Curtis "Ovid" Poe, C<< <ovid at cpan.org> >>

=head1 ISSUE TRACKER & CODE REPOSITORY

An issue tracker and the code repository are available at L<http://github.com/reneeb/Sub-Called>.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
