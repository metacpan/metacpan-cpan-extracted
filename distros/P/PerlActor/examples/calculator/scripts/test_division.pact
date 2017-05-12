# Script to check multiplication

# 1 / 1 = 1

NewCalculator

CheckDisplayReads	0

PressKeys			1
CheckDisplayReads	1

PressKeys			/
CheckDisplayReads	1

PressKeys			1
CheckDisplayReads	1

PressKeys			=
CheckDisplayReads	1

# 6 / 3 = 2

NewCalculator

CheckDisplayReads	0

PressKeys			6
CheckDisplayReads	6

PressKeys			/
CheckDisplayReads	6

PressKeys			3
CheckDisplayReads	3

PressKeys			=
CheckDisplayReads	2

# Division by 0

NewCalculator

CheckDisplayReads	0

PressKeys			1
CheckDisplayReads	1

PressKeys			/
CheckDisplayReads	1

PressKeys			0
CheckDisplayReads	0

PressKeys			=
CheckDisplayReads	E

