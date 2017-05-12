package Monorail::SQLTrans::Producer::PostgreSQL;
$Monorail::SQLTrans::Producer::PostgreSQL::VERSION = '0.4';
use base 'SQL::Translator::Producer::PostgreSQL';

sub drop_view {
    my ($view, $options) = @_;

    my $generator = SQL::Translator::Producer::PostgreSQL::_generator($options);

    return sprintf('DROP VIEW %s', $generator->quote($view->name));
}

sub alter_view {
    my ($view, $options) = @_;

    my $sql = SQL::Translator::Producer::PostgreSQL::create_view($view, \%options);

    $sql =~ s/^CREATE/CREATE OR REPLACE/m;

    return $sql;
}


1;
