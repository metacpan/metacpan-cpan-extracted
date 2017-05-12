# $File: //depot/OurNet-Query/Template.pm $ $Author: autrijus $
# $Revision: #5 $ $Change: 1498 $ $DateTime: 2001/08/02 00:02:46 $

package OurNet::Template;
use 5.006;

$OurNet::Template::VERSION = '0.06';

use strict;
use warnings;
use Template::Parser;
use base qw/Template/;

=head1 NAME

OurNet::Template - Template Toolkit extraction and generation

=head1 SYNOPSIS

    use OurNet::Template;
    use Data::Dumper;

    my $obj = OurNet::Template->new();
    my $template = << '.';
    <ul>[% FOREACH record %]
    <li><A HREF="[% url %]">[% title %]</A>: [% rate %] - [% comment %].
    [% _ %]
    [% END %]</ul>
    .

    my $document = << '.';
    <html><head><title>Great links</title></head><body>
    <ul><li><A HREF="http://slashdot.org">News for nerds.</A>: A+ - nice.
    this text is ignored.</li>
    <li><A HREF="http://microsoft.com">Where do you want...</A>: Z! - yeah.
    this text is ignored, too.</li></ul>
    .

    print Data::Dumper::Dumper(
	$obj->extract($template, $document)
    );

    # $obj->generate($document, $params); # not yet

=head1 DESCRIPTION

This module is a subclass of the standard I<Template> toolkit, with 
added template extraction functionality, which means you can take
a I<process()>ed document and the original template together, and get 
the original data structure back.

The C<extract> method takes three arguments: the template file itself
(leave it undefined if already initialized), a scalar to match against
it, and an optional external hash reference to store the extracted
values.

Extraction is done by transforming the result from I<Template::Parser>
to a highly esoteric regular expression, which utilizes the (?{...}) 
construct to insert matched parameters into the hash reference. The
special C<[% _ %]> directive is understood as C<(?:[\x00-\xff]*?)> 
in regex terms, i.e. "ignore everything between this identifier and
the next".

This module is used primarily in the I<OurNet> distributed storage
platform by I<OurNet::Site> and I<OurNet::WebBuilder> components; any 
use outside it should be considered experimental.

=head1 CAVEATS

Currently, the extract function only understands C<[% GET %]>, C<[% SET %]>
and C<[% FOREACH %]> directives, since C<[% WHILE %]>, C<[% CALL %]> and
C<[% SWITCH %]> blocks are next to impossible to extract correctly.

The C<generate> method is not working at all; it's supposed to take a data 
structure and the preferred rendering, and automagically generate a template 
to do the transformation. If you're into related research, please mail any 
ideas to me.

=head1 BUGS

Nested capturing will sometimes suffer from off-by-one errors with perl 
v5.7.1 or earlier; later versions supports the <$^N> variable and is
exempt from such errors.

There is no support for different I<PRE_CHOMP> and I<POST_CHOMP> settings 
internally, so extraction could fail silently on wrong places.

=cut

my ($params, $flagroot);

sub generate {
    die 'Template generation is not yet accomplished.';
}

sub extract {
    my ($self, $template, $document, $ext_param) = @_;
    my ($output, $error);

    if (!defined($self->{regex})) {
        OurNet::Template::Extract->set_param($ext_param);
        $params = { %{$flagroot} = () };

        my $parser = Template::Parser->new({
            PRE_CHOMP  => 1,
            POST_CHOMP => 1,
        });
    
        $parser->{ FACTORY } = ref($self).'::Extract';
	$template = $$template if UNIVERSAL::isa($template, 'SCALAR');
	$template =~ s/\n+$//;

        $self->{regex} = $parser->parse($template)->{ BLOCK };
    }

    if ($document) {
        use re 'eval';
        print "Regex: [$self->{regex}]\n" if $::DEBUG;
        return $document =~ /$self->{regex}/s ? $params : undef;
    }
}

sub _validate {
    my $vars = shift;
    my $obj;

    my ($flagnode, $lastvar) = _adjust($flagroot, @_);
    $obj = (_adjust($params, @_))[0]->{$lastvar};
    return unless UNIVERSAL::isa($obj, 'ARRAY');

    @{$obj} = grep {
	my $entry = $_;
 	scalar (grep { exists $entry->{$_} } @{$vars}) == scalar @{$vars};
    } @{$obj};
}

sub _set {
    my ($var, $val, $num) = splice(@_, 0, 3);
    my $obj;

    if (@_) {
        my ($flagnode, $lastvar) = _adjust($flagroot, @_);

        $obj = (_adjust($params, @_))[0]->{$lastvar}[
	    $flagnode->{$lastvar}{$num}++
	] ||= {};
    }
    else {
        $obj = $params;
    }

    ($obj, $var) = _adjust($obj, $var);
    $obj->{$var} = $val;
    
    return;
}

sub _adjust {
    my ($obj, $val) = (shift, pop);

    $obj = $obj->{$_} ||= {} foreach @_;
    return ($obj, $val);
}

1;

package OurNet::Template::Extract;

use strict;
use warnings;

my $count      = 0;
my $ext_param  = {};
my $last_regex = '';
my @vars;

sub set_param { 
    $ext_param = $_[-1] if defined $_[-1];
}

sub template {
    my $reg = $_[1];

    $count = 0;
    $reg =~ s/, \*\*//g; # this is safe because normal *s are escaped
    return $reg;
}

sub block {
    return join('', @{ $_[1] || [] });
}

sub ident {
    return join(',', map {$_[1][$_ * 2]} (0 .. int($#{$_[1]}) / 2));
}

sub get {
    return '.*?' if ($_[1] eq "'_'");

    ++$count; # which capturing parenthesis is this?

    # ** is the placeholder for parent tree in foreach() 
    $last_regex = ($] >= 5.007002)
	? "(?{_set($_[1], \$^N, $count, **)})"
	: "(?{_set($_[1], \$$count, $count, **)})";

    push @vars, $_[1];

    return "(.*?)";
}

sub set {
    return unless defined $ext_param;

    my @parents = map {$_[1][0][$_ * 2]} (0 .. int($#{$_[1][0]}) / 2);
    my $val = $_[1][1];
    my ($obj, $var);
    
    $_ = substr($_, 1, -1) foreach @parents;

    ($obj, $var) = OurNet::Template::_adjust($ext_param, @parents);
    $obj->{$var} = $val;
    
    return '';
}

sub textblock {
    my $ret = quotemeta($_[1]) . $last_regex;

    $last_regex = '';
    return $ret;
}

sub foreach {
    my $reg = $_[4];

    $last_regex = "(?{_validate([".join(',', @vars)."], $_[2])})";
    undef @vars;

    $reg =~ s/\*\*/$_[2]/g; # this is safe because normal *s are escaped
    return "(?:$reg)*";
}

sub text {
    return $_[1];
}

sub quoted {
    my $output = '';

    foreach my $token (@{$_[1]}) {
        if ($token =~ m/^'(.+)'$/) { # nested hash traversal
            $output .= '$';
            $output .= "{$_}" foreach split("','", $1);
        }
        else {
            $output .= $token;
        }
    }
    return $output;
}

our $AUTOLOAD;

sub AUTOLOAD {
    return unless $::DEBUG;

    require Data::Dumper;
    $Data::Dumper::Indent = 1;

    my $output = "\n$AUTOLOAD -";

    for my $arg (1..$#_) {
        $output .= "\n    [$arg]: ";
        $output .= ref($_[$arg]) 
	    ? Data::Dumper->Dump([$_[$arg]], ['_']) 
	    : $_[$arg];
    }

    print $output;

    return '';
}

1;

package OurNet::Template::Generate;

use strict;
use warnings;

1;

=head1 SEE ALSO

L<Template>, L<Template::Parser>, L<OurNet::Site>, L<OurNet::WebBuilder>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.org>

=head1 COPYRIGHT

Copyright 2001 by Autrijus Tang E<lt>autrijus@autrijus.org>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
