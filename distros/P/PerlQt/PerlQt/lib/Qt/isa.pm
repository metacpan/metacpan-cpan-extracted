package Qt::isa;
use strict;

sub import {
    no strict 'refs';
    my $class = shift;
    my $caller = (caller)[0];

    # Trick 'use' into believing the file for this class has been read
    my $pm = $caller . ".pm";
    $pm =~ s!::!/!g;
    unless(exists $::INC{$pm}) {
	$::INC{$pm} = $::INC{"Qt/isa.pm"};
    }

    for my $super (@_) {
	push @{ $caller . '::ISA' }, $super;
	push @{ ${$caller . '::META'}{'superClass'} }, $super; # if isa(QObject)?
    }

    *{ $caller . '::className' } = sub {	# closure on $caller
	return $caller;
    };

    ${ $caller. '::_INTERNAL_STATIC_'}{'SUPER'} = bless {}, "  $caller";
    Qt::_internal::installsuper($caller) unless defined &{ $caller.'::SUPER' };   

    *{ $caller . '::metaObject' } = sub {
	Qt::_internal::getMetaObject($caller);
    };

    *{ $caller . '::import' } = sub {
	my $name = shift;    # classname = function-name
	my $incaller = (caller)[0];
        $incaller = (caller(1))[0] if $incaller eq 'if'; # work-around bug in package 'if'  pre 0.02
        (my $cname = $name) =~ s/.*::// and do
        { 
            *{ "$name" } = sub {
                $name->new(@_);
            } unless defined &{ "$name" };
        };
        my $p = defined $&? $&:'';
        $p eq ($incaller=~/.*::/?($p?$&:''):'') and
	    *{ "$incaller\::$cname" } = sub {
	        $name->new(@_);
	    };

        if(defined @{ ${$caller.'::META'}{'superClass'} } &&
           @{ ${$caller.'::META'}{'superClass'} } )
        {
            # attributes inheritance
            for my $attribute( keys %{ ${$caller.'::META'}{'attributes'} } )
            {
                if(! defined  &{$incaller.'::'.$attribute })
                {
                    Qt::_internal::installattribute($incaller, $attribute);
                    ${ ${$incaller .'::META'}{'attributes'} }{$attribute} = 1;
                }
            }
        }
    };

    Qt::_internal::installautoload("  $caller");
    Qt::_internal::installautoload(" $caller");
    Qt::_internal::installautoload($caller);
    {
	package Qt::AutoLoad;
	my $autosub = \&{ " $caller\::_UTOLOAD" };
	*{ " $caller\::AUTOLOAD" } = sub { &$autosub };
        $autosub = \&{ "  $caller\::_UTOLOAD" };
	*{ "  $caller\::AUTOLOAD" } = sub { &$autosub };        
	$autosub = \&{ "$caller\::_UTOLOAD" };
	*{ "$caller\::AUTOLOAD" } = sub { &$autosub };
    }
    Qt::_internal::installthis($caller);

    # operator overloading
    *{ " $caller\::ISA" } = ["Qt::base::_overload"];
}

1;
