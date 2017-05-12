package AsciiToggle;

use Moose;
use Modern::Perl;

has get_domains_to_test => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub {
        [
            qw/
              whatever.name
              me.whatever.name
              me@whatever.name
              mx01.whatever.name
              test.xn--o3cw4h
              /
        ];
      }
);

1;

__END__

=head1 NAME

AsciiToggle - ShortDesc

=head1 SYNOPSIS

# synopsis...

=head1 DESCRIPTION

# longer description...


