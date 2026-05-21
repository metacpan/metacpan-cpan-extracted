# NOT RUN {
## Hollander & Wolfe (1973), 116.
## Mucociliary efficiency from the rate of removal of dust in normal
##  subjects, subjects with obstructive airway disease, and subjects
##  with asbestosis.
x <- c(2.9, 3.0, 2.5, 2.6, 3.2) # normal subjects
y <- c(3.8, 2.7, 4.0, 2.4)      # with obstructive airway disease
z <- c(2.8, 3.4, 3.7, 2.2, 2.0) # with asbestosis
kruskal.test(list(x, y, z))
## Equivalently,
x <- c(x, y, z)
g <- factor(rep(1:3, c(5, 4, 5)),
            labels = c("Normal subjects",
                       "Subjects with obstructive airway disease",
                       "Subjects with asbestosis"))
kt <- kruskal.test(x, g)
sprintf('%.14f', kt$p.value)
sprintf('%.14f', kt$statistic)
sprintf('%.14f', kt$parameter)
print(attributes(kt))
## Formula interface.
#require(graphics)
#boxplot(Ozone ~ Month, data = airquality)
#kruskal.test(Ozone ~ Month, data = airquality)
# }
