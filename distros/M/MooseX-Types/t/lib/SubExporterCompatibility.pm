package SubExporterCompatibility; {

    use MooseX::Types::Moose qw(Str);
    use MooseX::Types -declare => [qw(MyStr)];
    use Sub::Exporter -setup => { exports => [ qw(something MyStr) ] };

    subtype MyStr,
     as Str;

    sub something {
        return 1;
    }

} 1;
