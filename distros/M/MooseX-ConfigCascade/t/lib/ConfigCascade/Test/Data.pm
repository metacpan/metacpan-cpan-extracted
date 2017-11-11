package ConfigCascade::Test::Data;

sub new{
    my $class = shift;
    my $self = {
        types => [ qw(str hash array bool num int ) ],
        modes => [ qw( no_default has_default has_builder lazy ) ],
        rwo => [ qw(rw ro) ],

        expected => {
            str => sub{ $_[0].' from '.$_[1].' value' },
            hash => sub { return { $_[0].' from '.$_[1].' key' => $_[0].' from '.$_[1].' value' }},
            array => sub {[ $_[0].' from '.$_[1].' value' ]},
            bool => sub{ $_[1] eq 'package'?0:1 },
            num => sub{ 
                if ( $_[1] eq 'package' ){
                    return 2.2 if $_[0] =~ /has_default/;
                    return 3.3 if $_[0] =~ /has_builder/;
                    return 4.4 if $_[0] =~ /lazy/;
                } else {
                    return 1.2 if $_[0] =~ /no_default/;
                    return 2.4 if $_[0] =~ /has_default/;
                    return 3.6 if $_[0] =~ /has_builder/;
                    return 4.8 if $_[0] =~ /lazy/;
                }
            },
            int => sub{
                if ( $_[1] eq 'package' ){
                    return 22 if $_[0] =~ /has_default/;
                    return 33 if $_[0] =~ /has_builder/;
                    return 44 if $_[0] =~ /lazy/;
                } else {
                    return 2 if $_[0] =~ /no_default/;
                    return 4 if $_[0] =~ /has_default/;
                    return 6 if $_[0] =~ /has_builder/;
                    return 8 if $_[0] =~ /lazy/;
                }
            },

            conf => sub{
                return {

                    'ConfigCascade::Test::RW_Widget' => {

                        str_no_default => 'str_no_default from '.$_[0].' value',
                        str_has_default => 'str_has_default from '.$_[0].' value',
                        str_has_builder => 'str_has_builder from '.$_[0].' value',
                        str_lazy => 'str_lazy from '.$_[0].' value',


                        hash_no_default => {
                            'hash_no_default from '.$_[0].' key' => 'hash_no_default from '.$_[0].' value'
                        },
                        hash_has_default => {
                            'hash_has_default from '.$_[0].' key' => 'hash_has_default from '.$_[0].' value'
                        },
                        hash_has_builder => {
                            'hash_has_builder from '.$_[0].' key' => 'hash_has_builder from '.$_[0].' value'
                        },
                        hash_lazy => {
                            'hash_lazy from '.$_[0].' key' => 'hash_lazy from '.$_[0].' value'
                        },


                        array_no_default => [
                            'array_no_default from '.$_[0].' value'
                        ],
                        array_has_default => [
                            'array_has_default from '.$_[0].' value'
                        ],
                        array_has_builder => [
                            'array_has_builder from '.$_[0].' value'
                        ],
                        array_lazy => [
                            'array_lazy from '.$_[0].' value'
                        ],


                        bool_no_default => 1,
                        bool_has_default => 1,
                        bool_has_builder => 1,
                        bool_lazy => 1,

                        int_no_default => 2,
                        int_has_default => 4,
                        int_has_builder => 6,
                        int_lazy => 8,

                        num_no_default => 1.2,
                        num_has_default => 2.4,
                        num_has_builder => 3.6,
                        num_lazy => 4.8,
                        
                    },

                    'ConfigCascade::Test::RO_Widget' => {

                        str_no_default => 'str_no_default from '.$_[0].' value',
                        str_has_default => 'str_has_default from '.$_[0].' value',
                        str_has_builder => 'str_has_builder from '.$_[0].' value',
                        str_lazy => 'str_lazy from '.$_[0].' value',


                        hash_has_default => {
                            'hash_has_default from '.$_[0].' key' => 'hash_has_default from '.$_[0].' value'
                        },
                        hash_no_default => {
                            'hash_no_default from '.$_[0].' key' => 'hash_no_default from '.$_[0].' value'
                        },
                        hash_has_builder => {
                            'hash_has_builder from '.$_[0].' key' => 'hash_has_builder from '.$_[0].' value'
                        },
                        hash_lazy => {
                            'hash_lazy from '.$_[0].' key' => 'hash_lazy from '.$_[0].' value'
                        },


                        array_no_default => [
                            'array_no_default from '.$_[0].' value'
                        ],
                        array_has_default => [
                            'array_has_default from '.$_[0].' value'
                        ],
                        array_has_builder => [
                            'array_has_builder from '.$_[0].' value'
                        ],
                        array_lazy => [
                            'array_lazy from '.$_[0].' value'
                        ],

                        bool_no_default => 1,
                        bool_has_default => 1,
                        bool_has_builder => 1,
                        bool_lazy => 1,

                        int_no_default => 2,
                        int_has_default => 4,        
                        int_has_builder => 6,        
                        int_lazy => 8,

                        num_no_default => 1.2,
                        num_has_default => 2.4,
                        num_has_builder => 3.6,
                        num_lazy => 4.8,
                    }
                };
            }
        }
    };
    bless $self,$class;
    return $self;
}


sub expected{ return $_[0]->{expected}}
sub types{ return @{$_[0]->{types}}}
sub modes{ return @{$_[0]->{modes}}}
sub rwo{ return @{$_[0]->{rwo}}}

1;

