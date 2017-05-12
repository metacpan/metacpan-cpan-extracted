use strict;
use warnings;
use String::TT 'strip';
use Test::TableDriven (
    strip => {
        'Input' =>
          'Input',

        "\nInput" =>
          "Input",

        "\nInput\n" =>
          "Input\n",

        ' Input' =>
          'Input',

        ' Input ' =>
          'Input ',

        "\n Input\n" =>
          "Input\n",
        
        "\n    This is a test\n    Of indenting\n" =>
          "This is a test\nOf indenting\n",
        
        "\n    This is a test\n     Of indenting\n" =>
          "This is a test\n Of indenting\n",
        
        "\n    This is a test\n\n\n\n     Of indenting\n" =>
          "This is a test\n\n\n\n Of indenting\n",
    },
);

runtests;
