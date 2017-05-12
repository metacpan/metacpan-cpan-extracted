# $File: //member/autrijus/Template-Generate/lib/Template/Generate.pm $ $Author: autrijus $
# $Revision: #9 $ $Change: 8169 $ $DateTime: 2003/09/18 06:21:31 $ vim: expandtab shiftwidth=4

package Template::Generate;
$Template::Generate::VERSION = '0.04';

use 5.006001;
use strict;
use warnings;
our $DEBUG;

=head1 NAME

Template::Generate - Generate TT2 templates from data and documents

=head1 VERSION

This document describes version 0.04 of Template::Generate, released
September 18, 2003.

=head1 SYNOPSIS

    use Template::Generate;

    my $obj = Template::Generate->new;
    my $template = $obj->generate(
        {
            first	=> 'Autrijus',
            last	=> 'Tang',
            score	=> 55,
        } => "(Simon's Blog) Score: 55, Name: Autrijus Tang",
        {
            first	=> 'Simon',
            last	=> 'Cozens',
            score	=> 61,
        } => "(Simon's Blog) Score: 61, Name: Simon Cozens",
    );

    # "(Simon's Blog) Score: [% score %], Name: [% first %] [% last %]"
    print $template;

=head1 DESCRIPTION

This module generates TT2 templates.  It can take data structures and
rendered documents together, and deduce templates that could have
performed the transformation.

It is a companion to B<Template> and B<Template::Extract>; their
relationship is shown below:

    Template:           ($template + $data) ==> $document   # normal
    Template::Extract:  ($document + $template) ==> $data   # tricky
    Template::Generate: ($data + $document) ==> $template   # very tricky

This module is considered experimental.

=head1 METHODS

=head2 generate($data => $document, $data => $document, ...)

This method takes any number of ($data, $document) pairs, and returns a
sorted list of possible templates that can satisfy all of them.  In scalar
context, the template with most variables is returned.

You may set C<$Template::Generate::DEBUG> to a true value to display
generated regular expressions.

=head1 CAVEATS

Currently, the C<generate> method only handles C<[% GET %]> and
C<[% FOREACH %]> directives (both single-level and nested), although
support for C<[% ... %]> is planned in the future.

=cut

sub new {
    bless( {}, $_[0] );
}

sub generate {
    my $self = shift;

    my ( %seen, $final );
    while ( my $data = shift ) {
	my $document = shift;
	my $repeat   = keys(%$data);
	my ( @each, @this );
	do {
	    push @each, (
                @this = _try(
                    $data,
                    ( ref($document) ? $document : \$document ),
                    $repeat++,
                )
            );
	} while @this;
	%seen = map { $final = $_; $_ => 1 }
                grep { !%seen or $seen{$_} } @each
                or return;
    }
    return sort keys %seen if wantarray;
    return $final;
}

sub _try {
    my ( $data, $document, $repeat ) = @_;
    my $regex = "\\A\n";
    my $count = 0;

    $regex .= _any( \$count );
    for ( 1 .. $repeat ) {
	$regex .= _match( $data, \$count );
	$regex .= _any( \$count );
    }

    $regex .= "\\z\n";
    $regex .= "(??{_validate(\\\@m, \\\@rv, \$data)})\n";

    my ( @m, @rv );
    {
	use re 'eval';
        print $regex if $DEBUG;
	$regex      =~ s/\n//g;
	$$document  =~ m/$regex/s;
    }
    return @rv;
}

sub _match {
    my ( $data, $count, $prefix, $undef ) = @_;
    $prefix ||= '';
    my $rv = "(?:\n";
    foreach my $key ( sort keys %$data ) {
	my $value = $data->{$key};
	if ( !ref($value) ) {
	    $$count++;
            my $pat = '(' . quotemeta($value) . ')';
	    if ($undef) {
		$rv .= _set( $pat, $count, "[ undef, \$$$count ]})\n|" );
	    }
	    else {
		$rv .= _set( $pat, $count, "\\'{$prefix$key}'})\n|" );
	    }
	}
	elsif ( UNIVERSAL::isa( $value, 'ARRAY' ) ) {
            die "Array $key must have at least one element" unless @$value;

	    my $c1 = ++$$count;
	    $rv .= _set( '(.*?)', $count, "['[% FOREACH $key %]', \$$$count, '']})" );

	    $rv .= _match( $value->[0], $count, "$prefix$key}[0]{" );

	    my $c2 = ++$$count;
	    $rv .= _set( '(.*?)', $count, "['', \$$$count, '[% END %]']})" );

	    foreach my $idx ( 1 .. $#$value ) {
		++$$count;
		$rv .= _set( "(\\$c1)", $count, "[ undef, \$$c1 ]})" );

		$rv .= _match(
                    $value->[$idx],
                    $count,
		    "$prefix$key}[$idx]{",
                    'undef'
		);

		++$$count;
		$rv .= _set( "(\\$c2)", $count, "[ undef, \$$c2 ]})" );
	    }
	    $rv .= "|\n";
	}
	else {
	    die "Unsupported data type: " . ref($value);
	}
    }
    substr( $rv, -2 ) = ")\n";
    return $rv;
}

sub _any {
    my $count = shift;
    $$count++;
    return _set('(.*?)', $count, "\$$$count})");
}

sub _set {
    return "$_[0](?{\$m[\$-[${$_[1]}]][${$_[1]}] = $_[2]\n";
}

sub _validate {
    my ( $in, $out, $data ) = @_;
    my $idx  = 0;
    my %seen = ();
    my $rv   = '';
    while ( defined( my $ary = $in->[$idx] ) ) {
        my $prev = $idx;
        foreach my $val (grep defined, @$ary) {
            if ( ref($val) eq 'SCALAR' ) {
                $seen{$$val} = 1;
                my $obj = $data;
                my $cur = $$val;
                my $pos;
                while ($cur) {
                    if (substr($cur, 0, 1) eq '{') {
                        $pos = index($cur, '}');
                        $obj = $obj->{substr($cur, 1, $pos - 1)};
                    }
                    elsif (substr($cur, 0, 1) eq '[') {
                        $pos = index($cur, ']');
                        $obj = $obj->[substr($cur, 1, $pos - 1)];
                    }
                    else {
                        die "Impossible: $cur";
                    }
                    $cur = substr($cur, $pos + 1);
                }
                $idx += length( $obj );
                $rv .= "[% " .
                       substr( $$val, rindex( $$val, '{' ) + 1, -1 ) .
                       " %]";
            }
            elsif ( ref($val) eq 'ARRAY' ) {
                $rv .= join( '', @$val ) if @$val == 3;
                $idx += length( $val->[1] );
            }
            else {
                $rv .= $val;
                $idx += length($val);
            }
            last unless $prev == $idx;
        }
        last if $prev == $idx;
    }
    push @$out, $rv if keys(%seen) == keys(%$data);
    return '(?!)';
}

1;

=head1 SEE ALSO

L<Template>, L<Template::Extract>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2003 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

