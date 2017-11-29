count = [1, 2, 3, 4, 5]
fruits = ['apples', 'oranges', 'pears', 'bananas']
change = [1, 'pennies', 2, 'dimes', 3, 'quarters']

# durch eine Liste gehen
for number in count:
    print "This is count %d" % number

# gleich wie oben
for fruit in fruits:
    print "A fruit of type: %s" % fruit

for i in change:
    print "I got %r" % i

elements = []

# von 0 bis 5 zählen
for i in range(0, 6):
    print "Adding %d to the list." % i
    # append is a function that lists understand
    elements.append(i)

# ausgeben
for i in elements:
    print "Element was: %d" % i
