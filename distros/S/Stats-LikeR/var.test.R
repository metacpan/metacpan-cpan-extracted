#var.test                 package:stats                 R Documentation
#F Test to Compare Two Variances
#Description:
#     Performs an F test to compare the variances of two samples from
#     normal populations.
#Usage:
#     var.test(x, ...)
#     
#     ## Default S3 method:
#     var.test(x, y, ratio = 1,
#              alternative = c("two.sided", "less", "greater"),
#              conf.level = 0.95, ...)
#     
#     ## S3 method for class 'formula'
#     var.test(formula, data, subset, na.action, ...)
#     
#Arguments:
#    x, y: numeric vectors of data values, or fitted linear model
#:

x <- c(2.9, 3.0, 2.5, 2.6, 3.2) # normal subjects
y <- c(3.8, 2.7, 4.0, 2.4)      # with obstructive airway disease
z <- c(2.8, 3.4, 3.7, 2.2, 2.0) # with asbestosis
result <- var.test(x, y)
lapply(names(attributes(result)), function(attr_name) {
  cat("Attribute:", attr_name, "\n")
  print(attr(result, attr_name))
  cat("\n")
})

for (i in seq_along(result)) {
  cat("Component:", names(result)[i], "\n")
  print(result[[i]])
  cat("\n")
}
#-------
result <- var.test(x, y, ratio = 2)
for (i in seq_along(result)) {
  cat("Component:", names(result)[i], "\n")
  print(result[[i]])
  cat("\n")
}
sprintf('%.14f', result$estimate)
sprintf('%.14f', result$p.value)
sprintf('%.14f', result$statistic)
#--------
result <- var.test(x, y, conf.level = 0.99)
sprintf('%.14f', result$estimate)
sprintf('%.14f', result$p.value)
sprintf('%.14f', result$statistic)
