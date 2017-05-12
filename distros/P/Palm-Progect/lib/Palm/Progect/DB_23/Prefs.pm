
package Palm::Progect::DB_23::Prefs;

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

    my $progect_version = 23;

    # This interpretation of the prefs format is
    # NOT correct.  It is here to make sure that Progect
    # gets *something* in the database's prefs block.
    # Otherwise it assumes all sorts of wonky defaults.
    #
    # But currently setting (e.g.) the displayDueDates bit
    # will fubar all the prefs.


    #             ver    1  1  1  1  1  1  1  1  2  2
    # 0e 0f 0f 00 17 00 00 01 01 00 00 01 01 02 03 01 |................|
    #  2  2  2  2  2  2  t  .  .  . p. c.  .  .  .  ?
    # 01 00 00 00 00 00 00 00 10 06 06 00 00 00 00 04 |................|
    #  ?  ?  ?  ?  ?  ?  ?  3  3  3  c  c  4  4
    # 54 1c 00 04 54 1c 02 07 01 00 ff ff 02 01       |T...T.........  |


    my $progect_prefs = pack 'CC'           # version, reserved
                           . 'CCCC CCCC'    # first prefs group
                           . 'CCCC CCCC'    # second prefs group
                           . 'CCC CC C CC'  # task defaults
                           . 'CCC CCC CCC'  # padding ???

                           . 'CCC'        # third prefs group
                           . 'CC'         # flat categories 1 & 2
                           . 'CC',        # fourth prefs group


                        $progect_version,
                        0,   # reserved

                        ## first prefs group
                        0,   # hide done tasks
                        1,   # displayDueDates
                        1,   # displayPriorities
                        0,   # displayYear

                        0,   # useFatherStatus
                        1,   # autoSyncToDo
                        1,   # flatHideDone
                        2,   # flat_dated

                        ## second prefs group
                        3,   # flat_min_priority
                        1,   # flatOr
                        1,   # flatMin
                        0,   # boldMinPriority

                        0,   # boldMinDays
                        0,   # strikeDoneTasks
                        0,   # hideDoneProgress
                        0,   # hideProgress

                      ## task defaults
                      # f1 f2 f3  pri   comp     date  desc  note
                        0, 0, 0,  0,     0,       0,    0,    0,

                      ## Padding.  Can't figure this out
                        0,0,0,0,0,0,0,0,0,

                            # This is how the default record
                            # fields break out

                            # 0, # level
                            # 0, # next
                            # 0, # child
                            # 0, # opened
                            # 0, # prev
                            # 0, # reserved
                            #
                            # 0, # hasStartDate
                            # 0, # hasPred
                            # 0, # hasDuration
                            # 1, # hasDueDate
                            # 0, # hasToDo
                            # 0, # hasNote
                            #
                            # 0, # hasLink
                            # 0, # itemType
                            # 0, # hasXB
                            # 1, # newTask
                            # 1, # newFormat
                            # 0, # nextFormat
                            #
                            # 6, # priority
                            # 0, # completed
                            #
                            # 0, # date 1
                            # 0, # date 2
                            # 0, # date 3
                            # 0, # desc
                            # 0, # reserved (align)

                        ## third prefs group
                        0,   # flatSorted
                        0,   # flatDateLimit
                        1,   # completionDate

                        255, # flatCategories1
                        255, # flatCategories2

                        ## fourth prefs group
                        2,   # wordWrapLines
                        1;   # drawTreeLines

    my $appinfo = {
        sortOrder  => undef,
        other      => $progect_prefs,
    };

    &Palm::StdAppInfo::seed_StdAppInfo($appinfo);
    $self->appinfo($appinfo);
}

1;
