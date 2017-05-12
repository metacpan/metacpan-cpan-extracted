#!/usr/bin/perl -w                                         # -*- perl -*-

use strict;
use lib qw( ./lib ../lib );
use Pod::POM::Test;
#$Pod::POM::Node::DEBUG = 1;
my $DEBUG = 1;

my $text;
{  local $/ = undef;
   $text = <DATA>;
}

ntests(27);

my ($parser, $pom, @warn, @warnings);

$parser = Pod::POM->new( );
$pom = $parser->parse_text( $text );
assert( $pom );
@warn = $parser->warnings();
match( scalar @warn, 6 );
match( $warn[0], 'over expected a terminating back at <input text> line 14' );
match( $warn[1], 'head1 expected a title at <input text> line 18' );
match( $warn[2], 'unexpected item at <input text> line 22' );
match( $warn[3], "expected '>>' not '>' at <input text> line 27" );
match( $warn[4], "unterminated 'B<<' starting at <input text> line 26" );
match( $warn[5], "spurious '>' at <input text> line 29" );

my $fullwarn1 = join("\n", @warn);

$SIG{__WARN__} = sub {
    my $msg = join('', @_);
    chomp($msg);
#    print "warning: [$msg]\n";
    push(@warnings, $msg);
};

$parser = Pod::POM->new( warn => 1 );
$pom = $parser->parse_text( $text );
assert( defined $pom );
@warn = $parser->warnings();
match( scalar @warn, 6 );
match( scalar @warnings, 6 );

foreach (@warn) {
    match( shift @warnings, $_ );
}

my $fullwarn2 = join("\n", @warn);

@warnings = ();
sub warnsub {
    my $msg = shift;
    push(@warnings, "[$msg]");
}

$parser = Pod::POM->new( warn => \&warnsub );
$pom = $parser->parse_text( $text );
assert( defined $pom );
@warn = $parser->warnings();
match( scalar @warn, 6 );
match( scalar @warnings, 6 );

foreach (@warn) {
    match( shift @warnings, "[$_]" );
}


$parser = Pod::POM->new( warn => 1 );
$pom = $parser->parse_text("=head1 Foo\n\nBlah blah");
assert( defined $pom );

#use Data::Dumper;
#$Data::Dumper::Indent=1;
#print Dumper($pom);
#print $pom;

__DATA__
=head1 NAME

A test Pod document.

=head1 DESCRIPTION

This Pod document contains errors that should raise warnings
but not fatal errors.

=over 4

=item Foo

=head1 NEXT

This is the next section.

=head1

Missing head1 title!

=item foo

This shouldn't be outside an =over!

This B<< text isn't properly terminated.
>oh dear!

Blah > Blah
