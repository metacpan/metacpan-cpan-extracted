package t::App;

{
    package Foo;
    use Mouse;
    use MouseX::Types::DateTime;

    has 'datetime' => (is => 'rw', isa => 'DateTime',           coerce => 1, required => 0);
    has 'duration' => (is => 'rw', isa => 'DateTime::Duration', coerce => 1, required => 0);
    has 'timezone' => (is => 'rw', isa => 'DateTime::TimeZone', coerce => 1, required => 0);
    has 'locale'   => (is => 'rw', isa => 'DateTime::Locale',   coerce => 1, required => 0);
}

{
    package Bar;
    use Mouse;
    use MouseX::Types::DateTime qw(DateTime Duration TimeZone Locale);

    has 'datetime' => (is => 'rw', isa => DateTime, coerce => 1, required => 0);
    has 'duration' => (is => 'rw', isa => Duration, coerce => 1, required => 0);
    has 'timezone' => (is => 'rw', isa => TimeZone, coerce => 1, required => 0);
    has 'locale'   => (is => 'rw', isa => Locale,   coerce => 1, required => 0);
}

1;
