# XXX WARNING: This has *absolutely* no practical use.   XXX #
# XXX No interface is stable. Hack it at your own peril. XXX #

# This code used to be much longer, but thanks to Pattern Designs,
# much of those are obsolete & outdated. :-( I'll port more of
# them in the coming days. -- autrijus 2000/10/11 12:27am

package OurNet::Template;
require 5.005;

$OurNet::Template::VERSION = '0.02';

use strict;
use Template;
use Template::Parser;
use vars qw/$params @stack $idea/;
use base qw/Template/;

sub generate {
    my ($self, $params, $document) = @_;
    die "Template Generation, the holy grail, is of yet unsupported.";
}

sub extract {
    $_[3] ||= {} if $#_ >= 3;
    my ($self, $template, $document, $extparam) = @_;
    my ($output, $error);
    
    unless (defined $self->{regex}) {
        $OurNet::Extract::extparam = $extparam;
        $params = {@stack = %{$idea} = ()};

        my $parser = Template::Parser->new({
            PRE_CHOMP => 1,
            POST_CHOMP => 1,
        });
    
        $parser->{ FACTORY } = 'OurNet::Extract';
        $self->{regex} = $parser->parse(ref($template) eq 'SCALAR' ? $$template : $template)->{ BLOCK };
    }

    if ($document) {
        # print "Regex: [$self->{regex}]\n";
        use re 'eval';
        return $document =~ /$self->{regex}/s ? $params : undef;
    }
}

sub _set {
    my ($var, $val, $num, $pos, $loop) = @_;
    my $obj;

    if ($loop) {
        my ($newidea, $loopy) = _adjust($idea, $loop);
        $idea->{$num}{$pos} ||= $newidea->{$loopy}{$num}++;
        return unless $idea->{$num}{$pos};

        ($obj, $loopy) = _adjust($params, $loop);
        $obj = $obj->{$loopy}[$idea->{$num}{$pos} - 1] ||= {};
    }
    else {
        $obj = $params;
    }

    ($obj, $var) = _adjust($obj, $var);
    $obj->{$var} = $val;
    
    return;
}

sub _adjust {
    my ($obj, $var) = @_;

    until ($#{$var} == 0) {
        $obj = $obj->{shift(@{$var})} ||= {};
    }

    $var = $var->[0];
    
    return ($obj, $var);
}

1;


package OurNet::Extract;
$OurNet::Extract::VERSION = '0.01';

require 5.005;
use strict;
use vars qw/$AUTOLOAD $count $extparam/;

$count = 0;

sub template {
    $count = 0;
    return $_[1];
}

sub block {
    # print "block: { @_[1..$#_] }\n";
    return join("", @{ $_[1] || [] });
}

sub ident {
    # print "ident: { @{$_[1]} }\n";
    return '[' . join(',', map {$_[1][$_*2]} (0..int($#{$_[1]})/2)). ']';
}

sub get {
    # print "get: { @_[1..$#_] }\n";
    if ($_[1] eq "['_']") {
        return '(?:[\x00-\xff]*?)';
    }
    else {
        $count++;
        return "([\\x00-\\xff]*?)(?{
    _set($_[1], \$$count, $count, \$-[$count]) ###
})";
    }
}

sub set {
    return unless defined $extparam;

    my $var = [(map {$_[1][0][$_*2]} (0..int($#{$_[1][0]})/2))];
    my $val = $_[1][1];
    my $obj;
    
    foreach my $token (@{$var}) {
        $token = substr($token, 1, -1);
    }
    ($obj, $var) = OurNet::Template::_adjust($extparam, $var);
    $obj->{$var} = $val;
    
    return '';
}

sub textblock {
    # print "textblock: { @_[1..$#_] }\n";
    return quotemeta($_[1]);
}

sub foreach {
    # print "foreach: { @_[1..$#_] }\n";
    my $reg = $_[4];
    $reg =~ s/\]\) ###/], $_[2])/g;
    return "(?:$reg)*";
}

sub text {
    return $_[1];
}

sub quoted {
    my $output = '';
    foreach my $token (@{$_[1]}) {
        if ($token =~ m/^\[\'(.+)\'\]$/) {
            $output .= '$';
            $output .= "{  $_  }" foreach split("','", $1);
        }
        else {
            $output .= $token;
        }
    }
    return $output;
}

# tracking uncaptured directives
sub AUTOLOAD {
    use Data::Dumper;
    $Data::Dumper::Indent = 1;
    my $output = "\n$AUTOLOAD -";
    for my $arg (1..$#_) {
        $output .= "\n    [$arg]: ";
        $output .= ref($_[$arg]) ? Data::Dumper->Dump([$_[$arg]], ['_']) : $_[$arg];
    }
    print $output;
    return '';
}

1;


package OurNet::Generate;
$OurNet::Generate::VERSION = '0.01';

require 5.005;
use strict;
use vars qw/$AUTOLOAD $count/;


1;
