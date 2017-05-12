package Minions::_Guts;

use Digest::MD5 qw( md5_hex );

our %obfu_name;

sub obfu_name {
    my ($name, $spec) = @_;

    if ($spec->{no_attribute_vars} || ! $obfu_name{$name}) {
        return "-$name";        
    }
    else {
        return $obfu_name{$name};
    }
}

sub attribute_sym {
    my $datum = shift || $$;

    return substr(md5_hex($datum), 0 ,8);
}

1;
