package Nginx::Runner::Config;

use strict;
use warnings;

sub encode {
    my $config_data = shift;
    my $indent = shift || 0;

    my $indent_symbols = '';
    $indent_symbols .= '    ' for (1 .. $indent);

    my $config = '';

    foreach my $token (@$config_data) {
        my $name = shift @$token;

        my $token_string = $indent_symbols . $name;
        my $token_string_suffix = ";\n";

        foreach my $item (@$token) {
            unless (ref $item) {
                $token_string .= " $item";
            }
            else {
                $token_string = "\n$token_string {\n";
                $token_string .= encode($item, $indent + 1);
                $token_string .= $indent_symbols . "}\n";

                $token_string_suffix = '';
            }
        }

        $config .= $token_string . $token_string_suffix;
    }

    $config;
}

1;
