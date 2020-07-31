Set($AutomaticAssignmentFilters, [qw(
    ExcludedDates
    MemberOfGroup
    MemberOfRole
    WorkSchedule
    UserDefined
)]) unless $AutomaticAssignmentFilters;

Set($AutomaticAssignmentChoosers, [qw(
    ActiveTickets
    Random
    RoundRobin
    TimeLeft
    UserDefined
)]) unless $AutomaticAssignmentChoosers;

1;

