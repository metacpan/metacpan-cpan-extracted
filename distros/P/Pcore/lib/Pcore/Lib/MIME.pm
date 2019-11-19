package Pcore::Lib::MIME;

use Pcore -export;
use Pcore::Lib::Scalar qw[is_plain_arrayref];

our $DATA;

sub _load_data {
    if ( !defined $DATA ) {
        $DATA = $ENV->{share}->read_cfg('/Pcore/data/mime.yaml');    ## no critic qw[Variables::RequireLocalizedPunctuationVars]

        state $get_tags = sub ($data) {
            my $type = shift $data->@*;

            push $data->@*, split m[/]sm, $type, 2;

            my $tags = { map { $_ => 1 } $data->@* };

            # text types can be compressed
            $tags->{compress} = 1 if exists $tags->{text};

            return $type, $tags;
        };

        for my $key (qw[custom_suffix filename suffix]) {
            for my $name ( keys $DATA->{$key}->%* ) {
                $DATA->{$key}->{$name} = [ $get_tags->( $DATA->{$key}->{$name} ) ];
            }
        }

        # compile shebang
        for ( my $i = 0; $i <= $DATA->{shebang}->$#*; $i++ ) {
            my $re = shift $DATA->{shebang}->[$i]->@*;

            $DATA->{shebang}->[$i] = [ qr/$re/m, $get_tags->( $DATA->{shebang}->[$i] ) ];    ## no critic qw[RegularExpressions::RequireDotMatchAnything]
        }
    }

    return;
}

sub update {
    print 'updating mime.yaml ... ';

    my $res = P->http->get('https://svn.apache.org/viewvc/httpd/httpd/trunk/docs/conf/mime.types?view=co');

    if ($res) {
        my $data = $ENV->{share}->read_cfg('/Pcore/data/mime.yaml');

        my $suffixes = $data->{suffix};

        for my $line ( split /\n\r?/sm, $res->{data}->$* ) {
            next if $line =~ /\A\s*#/sm;

            my @tokens = split /\s+/sm, $line;

            my $type = shift @tokens;

            for my $suffix (@tokens) {
                if ( !exists $suffixes->{$suffix} ) {
                    $suffixes->{$suffix} = [$type];
                }
                elsif ( $suffixes->{$suffix}->[0] ne $type ) {
                    $suffixes->{$suffix}->[0] = $type;

                    # TODO update type in custom_suffix, filename, shebang branches
                }
            }
        }

        $ENV->{share}->write( '/Pcore/data/mime.yaml', $data );

        undef $DATA;
    }

    say $res;

    return $res;
}

sub mime_shebang ( $shebang ) {
    _load_data if !defined $DATA;

    for my $item ( $DATA->{shebang}->@* ) {
        return [ $item->[1], $item->[2] ] if $shebang =~ $item->[0];
    }

    return;
}

sub mime_filename ( $filename ) {
    _load_data if !defined $DATA;

    return $DATA->{filename}->{$filename};
}

sub mime_custom_suffix ( $suffix ) {
    _load_data if !defined $DATA;

    return $DATA->{custom_suffix}->{$suffix} // $DATA->{custom_suffix}->{ lc $suffix };
}

sub mime_suffix ( $suffix ) {
    _load_data if !defined $DATA;

    return $DATA->{suffix}->{ lc $suffix };
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 32                   | ControlStructures::ProhibitCStyleForLoops - C-style "for" loop used                                            |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Lib::MIME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
