package MongoDBx::Tiny::Attributes;
use strict;

=head1 NAME

MongoDBx::Tiny::Attributes - offering field attributes

=head1 SYNOPSIS

  package My::Data::Foo;

  use MongoDBx::Tiny::Document;

  COLLECTION_NAME 'foo';

  ESSENTIAL q/code/;
  FIELD 'code', INT, LENGTH(10), DEFAULT('0'), REQUIRED;
  FIELD 'name', STR, LENGTH(30), DEFAULT('noname');

  # you can also define customized one.
  
  FIELD 'some', &SOME_ATTRIBUTE;
  sub SOME_ATTRIBUTE {
	name     => 'SOME_ATTRIBUTE',
	callback => sub {
	    my $target = shift;
            return MongoDBx::Tiny::Attributes::OK;
        },
  }

=cut

our @ISA    = qw/Exporter/;
our @EXPORT = qw/INT UINT HEX STR ENUM DATETIME TIMESTAMP SCALAR REF ARRAY HASH REGEX
		 LENGTH NOT_NULL OID DEFAULT REQUIRED
		 NOW READ_ONLY OK FAIL
		/;

use constant OK       => 1;
use constant FAIL     => 0;

=head2 callback arguments

  callback = sub {
       my $target = shift;
       my $tiny   = shift;
       my $opt    = shift; # state => 'insert|update'
       return FAIL, { message => 'error' };
       return OK,   { target => $target  }; # override target if you want
  }

=cut

=head1 ATTRIBUTES

=cut

=head2 LENGTH

  LENGTH(255)

=cut

sub LENGTH {
    my $max = pop;
    my $min = pop;

    return {
	name     => 'LENGTH',
	callback => sub {
	    my $target = shift;
	    return OK unless defined $target;
            if (ref $target eq 'ARRAY') {
                if ( @$target > $max ||  (defined $min && @$target < $min) ) {
                    return FAIL, { message => 'invalid' };
                }
            }else{
                if ( length($target) > $max || ( defined $min && length($target) < $min ) ) {
                    return FAIL, { message => 'invalid' };
                }
            }
            return OK;
        },
    };
}

=head2 INT

=cut

sub INT {
    return {
	name      => 'INT',
	callback  => sub {
	    my $target = shift;
	    return OK unless defined $target;
	    return FAIL,{ message => 'invalid' } unless $target =~ /\A[+-]?[0-9]+\z/;
	    return OK;
	},
    }
}

=head2 UINT

=cut

sub UINT {
    return {
	name      => 'UINT',
	callback  => sub {
	    my $target = shift;
	    return OK unless defined $target;
	    return FAIL,{ message => 'invalid' } if $target =~ /[^0-9]/;
	    return OK;
	},
    }
}

=head2 HEX

=cut

sub HEX {
    return {
	name     => 'HEX',
	callback => sub {
	    my $target = shift;
	    return OK unless defined $target;
            return FAIL,{ message => 'invalid' } unless $target =~ m/^[a-f\d]+$/;
            return OK;
        },
    };
}

=head2 STR

=cut

sub STR {
    return {
        name     => 'STR',
        callback => sub {
	    my $target = shift;
            return OK unless defined $target;
            return FAIL,{ message => 'invalid' } if ref $target;
            return OK;
        },
    }
}

=head2 ENUM

  ENUM('on','off')

=cut

sub ENUM {
    my @list = @_;
    return {
	name     => 'ENUM',
	callback => sub {
	    my $target = shift;
	    return OK unless defined $target;
	    my $message = sprintf "%s is available", join ",", @list;
	    return FAIL,{ message => $message } unless (grep { $target eq $_ } @list);
	    return OK;
	},
    }
}

=head2 REF

=cut

sub REF {
    my $type = shift;
    return {
	name     => 'REF',
	callback => sub {
	    my $target = shift;
	    return OK unless defined $target;
	    return FAIL unless ref $target eq $type;
	    return OK;
	},
    }
}

=head2 HASH

=cut

sub HASH {
    return {
	name     => 'HASH',
	callback => sub {
	    my $target = shift;
	    return OK unless defined $target;
	    return FAIL unless ref $target eq 'HASH';
	    return OK;
	},
    }
}

=head2 ARRAY

=cut

sub ARRAY {
    return {
	name     => 'ARRAY',
	callback => sub {
	    my $target = shift;
	    return OK unless defined $target;
	    return FAIL unless ref $target eq 'ARRAY';
	    return OK;
	},
    }
}

=head2 DATETIME

=cut

sub DATETIME {
    # xxx
    return {
	name     => 'DATETIME',
	callback => sub {
	    my $target = shift;
	    if ($target) {
		return FAIL,{ message => 'not DateTime object' } unless (ref $target) eq 'DateTime';
	    }
	    return OK;
	}
    }
}

=head2 TIMESTAMP

=cut

sub TIMESTAMP {
    # xxx
    return {
	name     => 'TIMESTAMP',
	callback => sub {
	    my $target = shift;
	    return OK;
	}
    }
}

=head2 REGEX

  REGEX('\d+')

=cut

sub REGEX {
    my $regex = shift;

    return {
	name     => 'REGEX',
	callback => sub {
	    my $target = shift;
	    return OK unless defined $target;
	    return FAIL, { message => 'not match' } unless $target =~ /${regex}/;
	    return OK;
	},
    }
}


=head2 NOT_NULL

=cut

sub NOT_NULL {
    return {
	name     => 'NOT_NULL',
	callback => sub {
	    my $target = shift;
	    return FAIL,{ message => 'undefined' } unless defined $target;
	    return OK;
	},
    }
}

=head2 OID

=cut

sub OID {
    return {
	name     => 'OID',
	callback => sub {
	    my $target = shift;

	    return OK unless defined $target;
	    unless (ref $target eq 'MongoDB::OID') {
                if( $target =~ /\A[a-fA-F\d]{24}\z/) {
                    $target = MongoDB::OID->new(value => $target);
                    return OK,{ target => $target };
                }else{
                    return FAIL,{ message => 'invalid' };
                }
	    }
	    return OK, { target => $target };
	},
    }
}

=head2 DEFAULT

  DEFAULT("foo")
  DEFAULT([])

=cut

sub DEFAULT {
    my $default = shift;
    return {
	name => 'DEFAULT',
	callback => sub {
	    my $target = shift;
            return OK,{ target => $target } if (defined $target && $target ne '');
	    if (ref $default eq 'CODE') {
		return OK,{ target => $default->($target) };
	    } else {
		return OK,{ target => $default };
	    }
	},
    }
}

=head2 REQUIRED

=cut

sub REQUIRED {
    return {
	name     => 'REQUIRED',
	callback => sub { return OK },
    }
}

=head2 NOW

DEFAULT(NOW('Asia/Tokyo')

=cut

sub NOW {
    # for DEFAULT
    my $time_zone = shift || 'local';
    if ($time_zone eq 'timestamp') {
	require MongoDB::Timestamp;
	return sub { MongoDB::Timestamp->new(sec => time, inc => 1) };
    } else {
	require DateTime;
	return sub { DateTime->now(time_zone => $time_zone) };
    }
}

=head2 READ_ONLY

=cut

sub READ_ONLY {
    return {
	name     => 'READ_ONLY',
	callback => sub {
	    my $target = shift;
	    my $tiny   = shift;
	    my $opt    = shift; # state => 'insert|update'
	    return FAIL, if ($opt->{state} eq 'update');
	    return OK;
	}
    }
}

1;

=head1 AUTHOR

Naoto ISHIKAWA, C<< <toona at seesaa.co.jp> >>

Kouji Tominaga, C<< <tominaga at seesaa.co.jp> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Naoto ISHIKAWA.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
