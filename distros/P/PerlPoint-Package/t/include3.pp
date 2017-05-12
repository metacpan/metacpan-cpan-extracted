
=Includes

$toBeRestored1=value1

$toBeRestored2=value2

$canBeOverwritten=value3

Original values: "$toBeRestored1", "$toBeRestored2", "$canBeOverwritten".

\INCLUDE{type=pp file="include4.pp" localize=__ALL__}

After 1st inclusion: "$toBeRestored1", "$toBeRestored2", "$canBeOverwritten".

\INCLUDE{type=pp file="include4.pp" localize="toBeRestored1, toBeRestored2"}

After 2nd inclusion: "$toBeRestored1", "$toBeRestored2", "$canBeOverwritten".

