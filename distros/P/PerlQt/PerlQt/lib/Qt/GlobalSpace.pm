package Qt::GlobalSpace;
use strict;
require Qt;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT;
our $allMeth = Qt::_internal::findAllMethods( Qt::_internal::idClass("QGlobalSpace") );
no strict 'refs';

for my $proto( keys %$allMeth )
{
    next if $proto =~ /operator\W/; # skip operators
    $proto =~ s/[\#\$\?]+$//;
    *{ $proto } = sub
                   {
                        $Qt::_internal::autoload::AUTOLOAD = "Qt::GlobalSpace\::$proto";
                        goto &Qt::GlobalSpace::AUTOLOAD
                   } unless defined &$proto;
     push @EXPORT, $proto;
}

our %EXPORT_TAGS = ( "all" => [@EXPORT] );

1;