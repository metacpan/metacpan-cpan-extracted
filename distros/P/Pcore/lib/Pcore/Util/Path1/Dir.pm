package Pcore::Util::Path1::Dir;

use Pcore -role;
use Pcore::Util::Scalar qw[is_plain_coderef];
use Fcntl qw[];

sub read_dir ( $self, @ ) {
    my $res;

    my %args = (
        max_depth   => 1,        # 0 - unlimited
        follow_link => 1,
        is_dir      => 1,
        is_file     => 1,
        is_sock     => 1,
        is_link     => undef,    # undef - do not check, 1 - add links only, 0 - skip links
        @_[ 1 .. $#_ ]
    );

    # must be without trailing '/'
    my $base = $self->to_abs->{to_string};

    return if !-d $base;

    my $prefix = $args{abs} ? "$base/" : '';

    my $read = sub ( $dir, $depth ) {
        my $dir_path = "${base}$dir";

        opendir my $dh, $dir_path or die qq[Can't open dir "$dir_path"];

        my @paths = readdir $dh or die $!;

        closedir $dh or die $!;

        for my $path (@paths) {
            next if $path eq '.' || $path eq '..';

            my $fpath = "${dir_path}$path";

            my ( $stat, $lstat );

            my $push = 1;

            if ( defined $args{is_link} ) {
                $lstat //= ( lstat $fpath )[2] & Fcntl::S_IFMT;

                if ( $lstat == Fcntl::S_IFLNK ) {
                    $push = 0 if !$args{is_link};
                }
                else {
                    $push = 0 if $args{is_link};
                }
            }

            if ( $push && !$args{is_file} ) {
                $stat //= ( stat $fpath )[2] & Fcntl::S_IFMT;

                $push = 0 if $stat == Fcntl::S_IFREG;
            }

            if ( $push && !$args{is_dir} ) {
                $stat //= ( stat $fpath )[2] & Fcntl::S_IFMT;

                $push = 0 if $stat == Fcntl::S_IFDIR;
            }

            if ( $push && !$args{is_sock} ) {
                $stat //= ( stat $fpath )[2] & Fcntl::S_IFMT;

                $push = 0 if $stat == Fcntl::S_IFSOCK;
            }

            push $res->@*, $prefix . substr( $dir, 1 ) . $path if $push;

            if ( !$args{max_depth} || $depth < $args{max_depth} ) {
                $stat //= ( stat $fpath )[2] & Fcntl::S_IFMT;

                if ( $stat == Fcntl::S_IFDIR ) {
                    if ( !$args{follow_link} ) {
                        $lstat //= ( lstat $fpath )[2] & Fcntl::S_IFMT;

                        next if $lstat == Fcntl::S_IFLNK;
                    }

                    __SUB__->( "${dir}$path/", $depth + 1 );
                }
            }
        }

        return;
    };

    $read->( '/', 1 );

    return $res;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 7                    | Subroutines::ProhibitExcessComplexity - Subroutine "read_dir" with high complexity score (29)                  |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 25                   | ValuesAndExpressions::ProhibitEmptyQuotes - Quotes used with a string containing no non-whitespace characters  |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 10                   | CodeLayout::RequireTrailingCommas - List declaration without trailing comma                                    |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Path1::Dir

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
