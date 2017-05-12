package Pcore::Util::Config::INI;

use Pcore;
use Pcore::Util::Text qw[decode_utf8 encode_utf8 trim];

sub from_ini ($str) {
    my $cfg;

    my $section = '_';

    my @lines = grep { $_ ne q[] } map { trim $_} split /\n/sm, decode_utf8 $str;

    for my $line (@lines) {

        # section
        if ( $line =~ /\A\[(.+)\]\z/sm ) {
            $section = $1;

            $cfg->{$section} = {} if !exists $cfg->{$section};
        }

        # not a section
        else {

            # comment
            if ( $line =~ /\A;/sm ) {
                next;
            }

            # variable
            else {
                my ( $key, $val ) = split /=/sm, $line, 2;

                if ( defined $val ) {
                    trim $val;

                    $val = undef if $val eq q[];
                }

                $cfg->{$section}->{ trim $key} = $val;
            }
        }
    }

    return $cfg;
}

sub to_ini ($hash) {
    my $str = q[];

    state $write_section = sub ( $str_ref, $section, $data ) {
        if ($section) {
            $str_ref->$* .= "\n" x 2 if $str_ref->$*;

            $str_ref->$* .= "[$section]";
        }

        for my $key ( sort keys $data->%* ) {
            $str_ref->$* .= "\n" if $str_ref->$*;

            $str_ref->$* .= "$key = " . ( defined $data->{$key} ? "$data->{$key}" : q[] );
        }

        return;
    };

    if ( exists $hash->{_} ) {
        $write_section->( \$str, q[], $hash->{_} );
    }

    for my $section ( sort grep { $_ ne '_' } keys $hash->%* ) {
        $write_section->( \$str, $section, $hash->{$section} );
    }

    encode_utf8 $str;

    return \$str;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Config::INI

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
