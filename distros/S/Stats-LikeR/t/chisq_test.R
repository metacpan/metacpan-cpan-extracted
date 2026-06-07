print_res_list <- function(res) {
	res_list <- unclass(res)
	# Print formatted output for each component in res_list
	# Numeric values are formatted to 15 decimal places
	for (component in names(res_list)) {
		cat(sprintf("\n========================================\n"))
		cat(sprintf(" Component: %s\n", component))
		cat(sprintf("========================================\n"))

		val <- res_list[[component]]

		if (is.numeric(val)) {
		# format() preserves matrix/vector dimensions and names 
		# while forcing exactly 15 decimal places.
		print(format(val, nsmall = 15, digits = 15), quote = FALSE)
		} else {
		print(val)
		}
	}
}
print('1D Array Test')
res <- chisq.test(c(10, 20, 30))
# 2. Unclass the object to expose the raw underlying named list
print_res_list(res)
#--------
print('2D Array Test (2x2 Matrix)')
res <- chisq.test(rbind(c(10, 15), c(20, 5)))
print_res_list(res)
#-------
print('2D Array Test 3x2 Matrix')
res <- chisq.test(rbind(c(10, 10, 20), c(20, 20, 20)))
print_res_list( res )
print('1D Hash Test')
res <- chisq.test(c(A=10, B=20, C=30))
print_res_list( res )
#----------
print('2D hash test')
res <- chisq.test(rbind(Group1=c(Success=10, Failure=15), Group2=c(Success=20, Failure=5)))
print_res_list( res )
