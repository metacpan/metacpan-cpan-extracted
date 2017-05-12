
=head1 NAME

Syntax::Highlight::JSON - Convert JSON to a pretty-printed and syntax-highlighted HTML representation

=cut

package Syntax::Highlight::JSON;

use strict;
use warnings;

use JSON::Streaming::Reader;
use IO::Scalar;

our $VERSION = "0.01";

sub highlight_stream {
    my ($in_stream) = @_;

    my $out_string = "";
    my $out_stream = IO::Scalar->new(\$out_string);
    my $reader = JSON::Streaming::Reader->for_stream($in_stream);

    _highlight($reader, $out_stream);

    return $out_string;
}

sub highlight_string {
    my ($in_string) = @_;

    my $out_string = "";
    my $out_stream = IO::Scalar->new(\$out_string);
    my $reader = JSON::Streaming::Reader->for_string($in_string);

    _highlight($reader, $out_stream);

    return $out_string;
}

sub highlight_stream_to_stream {
    my ($in_stream, $out_stream) = @_;

    my $reader = JSON::Streaming::Reader->for_stream($in_stream);

    _highlight($reader, $out_stream);
}

sub highlight_string_to_stream {
    my ($in_string, $out_stream) = @_;

    my $reader = JSON::Streaming::Reader->for_string($in_string);

    _highlight($reader, $out_stream);
}

sub _highlight {
    my ($jr, $out_stream) = @_;

    my $current_indent = 0;
    my $in_property = 0;
    my @mv_stack;
    my @p_stack;
    my $made_value = 0;

    my $tab = sub {
        $out_stream->print("    " x $current_indent);
    };
    my $pr = sub {
        $out_stream->print(@_);
    };
    my $push = sub {
        push @mv_stack, $made_value;
        $made_value = 0;
        push @p_stack, $in_property;
        $in_property = 0;
    };
    my $pop = sub {
        $made_value = pop @mv_stack;
        $in_property = pop @p_stack;
    };
    my $comma = sub {
        $out_stream->print(",") if $made_value;
        if ($in_property) {
            $out_stream->print(" ");
        }
        else {
            $out_stream->print("\n");
            $tab->();
        }
    };
    my $end_block = sub {
        if ($made_value) {
            $out_stream->print("\n");
            $tab->();
        }
    };

    $pr->('<pre class="json">');
    $jr->process_tokens(
        start_object => sub {
            $comma->();
            $pr->('<span class="j_obj"><span class="j_br">{</span><span class="j_obj_c">');
            $push->();
            $current_indent++;
        },
        end_object => sub {
            $current_indent--;
            $end_block->();
            $pop->();
            $pr->('</span><span class="j_br">}</span></span>'),
            $made_value = 1;
        },
        start_property => sub {
            my ($name) = @_;
            $comma->();
            $push->();
            $in_property = 1;
            $pr->('<span class="j_prp"><span class="j_st">', _json_string($name), '</span>:');
        },
        end_property => sub {
            $in_property = 0;
            $pop->();
            $made_value = 1;
            $pr->('</span>');
        },
        start_array => sub {
            $comma->();
            $pr->('<span class="j_arr"><span class="j_br">[</span><span class="j_arr_c">');
            $push->();
            $current_indent++;
        },
        end_array => sub {
            $current_indent--;
            $end_block->();
            $pop->();
            $pr->('</span><span class="j_br">]</span></span>'),
            $made_value = 1;
        },
        add_string => sub {
            my ($value) = @_;
            $comma->();
            $pr->('<span class="j_st">', _json_string($value), '</span>');
            $made_value = 1;
        },
        add_number => sub {
            my ($value) = @_;
            $comma->();
            $pr->('<span class="j_nu">', $value, '</span>');
            $made_value = 1;
        },
	add_boolean => sub {
	    my ($value) = @_;
	    $comma->();
	    $pr->('<span class="j_kw">', ($value ? 'true' : 'false'), '</span>');
	    $made_value = 1;
	},
	add_null => sub {
	    my ($value) = @_;
	    $comma->();
	    $pr->('<span class="j_kw">null</span>');
	    $made_value = 1;
	},
	error => sub {
	    my $error = shift;
	    die $error;
	},
    );
    $pr->('</pre>');


}

my %esc = (
    "\n" => '\n',
    "\r" => '\r',
    "\t" => '\t',
    "\f" => '\f',
    "\b" => '\b',
    "\"" => '\"',
    "\\" => '\\\\',
    "\'" => '\\\'',
);
sub _json_string {
    my ($value) = @_;

    $value =~ s/([\x22\x5c\n\r\t\f\b])/$esc{$1}/eg;
    $value =~ s/([\x00-\x08\x0b\x0e-\x1f])/'\\u00' . unpack('H2', $1)/eg;

    return '"'.$value.'"';
}

1;
