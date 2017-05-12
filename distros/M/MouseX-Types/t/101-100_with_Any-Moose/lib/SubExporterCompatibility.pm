package SubExporterCompatibility; {

    use Any::Moose 'X::Types::Moose' => [qw(Str)];
    use Any::Moose 'X::Types' => [-declare => [qw(MyStr)]];
    use Sub::Exporter -setup => { exports => [ qw(something MyStr) ] };

    subtype MyStr,
     as Str;

    sub something {
        return 1;
    }

}

1;
