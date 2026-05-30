ct <- cor.test(c(seq(1,10)), c(seq(10,1,-1)), method = 'spearman')

for (col in names(ct)) {
  val <- ct[[col]]
  cat(col, ": ", sep = "")
  
  if (is.numeric(val)) {
    # Print with 15 decimal places
    cat(sprintf("%.15f\n", val))
  } else {
    cat(val, "\n")
  }
}
ct <- cor.test(c(seq(1,200)), c(seq(200,1,-1)), method = 'kendall')
for (col in names(ct)) {
  val <- ct[[col]]
  cat(col, ": ", sep = "")
  
  if (is.numeric(val)) {
    # Print with 15 decimal places
    cat(sprintf("%.15f\n", val))
  } else {
    cat(val, "\n")
  }
}
