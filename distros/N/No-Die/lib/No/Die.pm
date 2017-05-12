package No::Die;

use Carp                        qw[carp croak];
use Params::Check               qw[check];
use Locale::Maketext::Simple    Style => 'gettext';

use strict;
use vars qw[$DIE $VERSION];

$VERSION = 0.02;

BEGIN { *CORE::GLOBAL::die = sub { goto &_nodie } }

my $Store = { files => [ ], packages => [ ] };

### for debugging purposes only ###
sub _store { return $Store };

sub import {
    my $self = shift;
    my ($pkg,$file) = caller;

    if( @_ ) {  
       
        my $tmpl = {
           files       => { default => [ ], strict_type => 1 },
           packages    => { default => [ ], strict_type => 1 },
        };     
        
        local $Params::Check::VERBOSE = 1;
        
        my $args = check( $tmpl, { @_ } )  
            or die qq[Improper arguments!];
        
        for( keys %$args ) {
            push @{$Store->{$_}}, @{$args->{$_}};
        }
            
    } 
    push @{$Store->{files}}, $file, $INC{'No/Die.pm'};
    push @{$Store->{packages}}, $pkg, __PACKAGE__;
        
    {   no strict 'refs';
        *{"${pkg}::DIE"} = *DIE;    
    }     
}

sub _nodie {
    my @call; my $flag;
    my ($pkg) = @call = caller;
    
    local $Params::Check::VERBOSE = 0;
    
    ### sort is important, because of caller order ###
    for my $key ( reverse sort keys %$Store ) {
        $flag++ if check(
                { $key => { allow => $Store->{$key} } },
                { $key => shift @call },
            );          
    };

    if( $flag ) {
        $DIE = undef;
        croak(@_);
    
    } else {
        carp loc(q[Unallowed '%1' requested from package '%2'], 'die', $pkg) if $^W;
        $DIE = "@_"; 
        return undef;
    }      
}
1;

__END__

=head1 NAME
No::Die

=head1 SYNOPSIS

    use No::Die;
    
    Some::Function::that_dies() 
        or warn "It tried to die with msg: $DIE\n";
    
=head1 DESCRIPTION

Only let modules die when you say it's OK.

=head1 EXPLENATION

Tired of using eval as a straightjacket on modules that have as much
interest in life as chronically depressed lemmings? Now there's a 24
hour suicide watch in L<No::Die>. Only modules you permit to die may -
the rest will just have to live with it. Their distress wil be noted
in an error variable and undef will be returned. The ultimate 
decision of life and death will be left to your application.    

=head1 USAGE

=head3 use [ packages => \@pkgs, files => \@files ]

By default, only die calls that are issued from the same package and
the same file that the call to C<use No::Die> was in, will be 
actually allowed to be executed.

You can override this by supplying extra file- and/or packagenames
that may also call die and have their request honoured.

=head3 $DIE

All functions that call C<die()> and are not allowed to, will have
undef returned to them. The error they attempted to throw will be 
stored in an exported variable called C<$DIE>.

=head1 DIAGNOSTICS

When running under warnings, C<No::Die> will issue a warning for all
unauthorized calls to C<die()> so you may inspect which unruly module
is attempting to take it's own life in your program.

=head1 CAVEATS

Some modules do not conceive the possibillity that a die might not
be honoured and do not explicitly end their subroutine, but do 
something like this:

    sub foo {
        ...
        die 'oops' if $condition;
        
        # go on with stuff
        ...
    }

The execution after the call to die will now happen, since the module
in question wasn't allowed to call C<die()> to begin with.    

=head1 NOTES

Apparently some people forget this: L<Carp::croak> and L<Carp::confess>
also use C<die()> under the hood, so they'll be affected as well by 
the use of L<No::Die>.
          
=head1 AUTHOR

Jos Boumans L<kane@cpan.org>

=head1 COPYRIGHT

This module is
copyright (c) 2003 Jos Boumans E<lt>kane@cpan.orgE<gt>.
All rights reserved.

This library is free software;
you may redistribute and/or modify it under the same
terms as Perl itself.
