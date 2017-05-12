
package Palm::Progect::DB_18::Prefs;

use Palm::Raw;
use Palm::StdAppInfo;


use strict;
use 5.004;

use CLASS;
use base qw(Class::Accessor Class::Constructor);

my @Accessors = qw(
    name
    appinfo
);


# Eventually handle these undef $appinfo->{other}, I think...:
#     format
# 	hideDoneTasks
# 	displayDueDates
# 	displayPriorities;
# 	displayYear;
# 	useFatherStatus;
# 	autoSyncToDo;
# 	flatHideDone;
# 	flatDated;
# 	flatMinPriority;
# 	flatOr;
# 	flatMin;
# 	boldMinPriority;
# 	boldMinDays;
# 	strikeDoneTasks;
# 	hideDoneProgress;
# 	hideProgress;
#
# 	taskDefaults; // embedded record structure... research
#
# 	flatSorted; // enum: none, datefirst, priorityfirst
# 	flatDateLimit; // 0 = no, 1 = overdue, 2 = today...
# 	completionDate; // true = record completion date
# 	flatCategories;
# 	wordWrapLines;
# 	drawTreeLines;

CLASS->mk_accessors(@Accessors);
CLASS->mk_constructor(
    Auto_Init    => \@Accessors,
    Init_Methods => '_init',
);

sub _init {
    my $self = shift;

    my %args = @_;

    $self->categories(delete $args{'categories'}) if exists $args{'categories'};

    $self->_seed_appinfo();
}

# Put the categories into the appinfo hash
sub categories {
    my $self = shift;

    my $categories = ref $_[0] eq 'ARRAY'? $_[0] : [ @_ ];

    # Add 'name' field if missing
    foreach my $cat (@$categories) {
        $cat->{'name'} = '' unless defined $cat->{'name'};
    }

    # pad out categories to 16
    if (@$categories < 16) {
        my $missing = 16 - @$categories;
        push @$categories, {
            'renamed' => 0,
            'name'    => '',
            'id'      => 0,
        } for 1..$missing;
    }

    $self->appinfo->{'categories'} = $categories;
}

sub packed_appinfo {
    my $self = shift;

    return &Palm::StdAppInfo::pack_StdAppInfo($self->{'appinfo'});
}

sub _seed_appinfo {
    my $self = shift;

    my $progect_prefs = pack 'C', 18;

    my $appinfo = {
        sortOrder       => undef,
        other           => $progect_prefs,
    };

    &Palm::StdAppInfo::seed_StdAppInfo($appinfo);
    $self->appinfo($appinfo);
}

1;
