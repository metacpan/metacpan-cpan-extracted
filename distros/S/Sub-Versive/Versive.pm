package Sub::Versive;

require 5.6.1;
use strict;
use warnings;
use Carp;
use Devel::Peek q/CvGV/;
no warnings 'redefine'; # Oh yes.

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Sub::Versive ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	append_to_sub
    prepend_to_sub
    builtinify
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.01';


# This *is* pure evil. 

sub _prep {
    my $orig = shift;
    my $ref;
    if (ref $orig eq "CODE") { 
        $ref = $orig;
        $orig = CvGV($orig);
        $orig =~ s/.//;
    } else {
        $ref = eval "\\\&$orig";# This is evil too.
    }
    if (not exists $Sub::Version::stash{$orig}) {
        $Sub::Version::stash{$orig}{orig} = $ref;
        my $code = 'sub '.$orig.' {
            for (@{$Sub::Version::stash{"'.$orig.'"}{precall}}) {
                my @x = $_->(@_);
                return @x if ($@); # Signal a return
            }
            my @rv = $Sub::Version::stash{"'.$orig.'"}{orig}->(@_);
            for (@{$Sub::Version::stash{"'.$orig.'"}{postcall}}) {
                my @x = $_->(@_);
                return @x if ($@); # Signal a return
            }
            return @rv;
        }';
        eval $code; $@ and die "$code:$@";
    }
    return ($ref, $orig);
}
sub append_to_sub (&\&) {
    my ($newcode, $orig) = @_;
    my $ref;
    ($ref, $orig) = _prep($orig);
    push @{$Sub::Version::stash{$orig}{postcall}}, $newcode;
};

sub prepend_to_sub (&\&) {
    my ($newcode, $orig) = @_;
    my $ref;
    ($ref, $orig) = _prep($orig);
    unshift @{$Sub::Version::stash{$orig}{precall}}, $newcode;
};

# Let's go, guys!

if (defined &UNIVERSAL::AUTOLOAD) { 
prepend_to_sub {
    my $foo = $UNIVERSAL::AUTOLOAD;
    $foo =~ s/.*:://;
    if (exists $Sub::Versive::builtins{$foo}) {
        $@="Die alien swine!";
        return $Sub::Versive::builtins{$foo}->(@_); 
    }
} &UNIVERSAL::AUTOLOAD;
}
else {
    eval <<'EOF';
    sub UNIVERSAL::AUTOLOAD { 
    my $foo = $UNIVERSAL::AUTOLOAD;
    $foo =~ s/.*:://;
    if (exists $Sub::Versive::builtins{$foo}) {
        return $Sub::Versive::builtins{$foo}->(@_); 
    }
    # Fake it.
    croak "Undefined subroutine $UNIVERSAL::AUTOLOAD called";
    }
EOF
}

sub builtinify (\&) {
    my $sub = shift;
    my $whence = CvGV($sub);
    $whence =~ s/.*:://;
    $Sub::Versive::builtins{$whence} = $sub;
}
1;
__END__

=head1 NAME

Sub::Versive - Subroutine pre- and post-handlers

=head1 SYNOPSIS

  use Sub::Versive qw(append_to_sub prepend_to_sub builtinify);
  
  sub foo { print "Hi there\n"; }

  append_to_sub  { print "Doing foo() now"; }     &foo;
  prepend_to_sub { print "Finished"; }            &foo;
  prepend_to_sub { print "Yes, it's stackable"; } &foo;

  prepend_to_sub { $@="Hijacked!"; do_something_else() }

  builtinify &foo;

  package bar;

  foo(); # Still works.

=head1 DESCRIPTION

The synopsis pretty much tells you all you need to know. You can add
pre- and post-actions to subroutines, stack them, have them force a
return, and make a subroutine available from everywhere. 

I'm sorry, incidentally, that this needs 5.6.1 and above, especially
since 5.6.1 isn't released right now. This is because of the prototyping
behaviour. If you want to make it work with 5.6.0, zap the prototypes
and pass subroutine references instead of subroutine names. I just
vastly prefer the syntax, that's all. You'll still need C<Devel::Peek>
from 5.6.0, though.

=head2 EXPORT

None by default, all three functions available. 

=head1 AUTHOR

Simon Cozens, C<simon@cpan.org>

=cut
