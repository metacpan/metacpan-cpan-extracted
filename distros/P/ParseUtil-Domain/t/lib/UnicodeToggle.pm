package UnicodeToggle;

use utf8;
use Moose;
use Modern::Perl;
has get_domains_to_test => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub {
        return [
            qw/
            bloß.de
            test.xn--o3cw4h
            bloß.co.at
            /
        ];
      }
);

"one, but we're not the same.";

__END__

=head1 NAME

UnicodeToggle - ShortDesc

=head1 SYNOPSIS

# synopsis...

=head1 DESCRIPTION

# longer description...


