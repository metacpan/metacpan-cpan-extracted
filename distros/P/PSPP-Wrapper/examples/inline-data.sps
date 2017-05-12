DATA LIST LIST 
 / make (A15) mpg weight price .
BEGIN DATA.
"AMC Concord",22,2930,4099
"AMC Pacer",17,3350,4749
"AMC Spirit",22,2640,3799
"Buick Century",20, 3250,4816
"Buick Electra",15,4080,7827
END DATA.

LIST.
save outfile="out.sav".