package Pask::Config;

use Carp;
use Config::INI::Reader;

use Pask::Container;

sub parse_mysql_config {
    my $config = shift;
    my $prefix = $config->{"prefix"};
    foreach (keys %{$config->{"schema"}}) {
        Pask::Container::set_database_config "$prefix$_", {
            "dsn" => "DBI:mysql:" . $config->{"schema"}{$_} . ";host=" . $config->{"ip"},
            "username" => $config->{"username"},
            "password" => $config->{"password"},
            "options" => { mysql_enable_utf8 => 1 }
        };
    }
}

sub parse_database_config {
    my $config = shift;
    my $database = $config->{"global"}{"database"};
    foreach (keys %{$database}) {
        my $database_config = undef;
        if ($database->{$_}) {
            $database_config = $config->{$database->{$_}} if $database->{$_};
            Carp::confess "can not find database ", $database->{$_}, " config" unless $database_config;
            if ($config->{"global"}{"default_database"} eq $_) {
                $database_config->{"prefix"} = "";
            } else {
                $database_config->{"prefix"} = "$_.";
            }
            parse_mysql_config $database_config if $database_config->{"type"} =~ /mysql/i;
        }
    }
}

sub parse_env_file {
    use Data::Dumper;
    my ($orginal, $target, $i, $prev_i, $prev_key) = (Config::INI::Reader->read_file(shift));
    foreach my $key (keys %$orginal) {
        $target->{$key} = {};
        foreach my $name (keys %{$orginal->{$key}}) {
            if ($name =~ /^\w+?(\.\w+){1,}$/) {
                $i = $target->{$key};
                foreach (split /\./, $name) {
                    $i->{$_} = {} unless exists $i->{$_};
                    $prev_i = $i;
                    $prev_key = $_;
                    $i = $i->{$_};
                }
                $prev_i->{$prev_key} = $orginal->{$key}{$name};
            } else {
                $target->{$key}{$name} = $orginal->{$key}{$name};
            }
        }
    }
    parse_database_config $target;
    $orginal;
}

1;
