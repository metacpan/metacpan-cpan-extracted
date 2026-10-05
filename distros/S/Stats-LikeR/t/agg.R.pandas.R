# Regenerates the frozen R side of t/agg.R.pandas.t.  Re-run it with
#
#     Rscript t/agg.R.pandas.R > /tmp/agg.R.pl
#
# and paste the output over the "BEGIN GENERATED (R)" .. "END GENERATED (R)"
# block of t/agg.R.pandas.t.  The test itself never runs R: everything this
# prints is a Perl literal.
#
# Written against R 4.6.1 (2026-06-24).  Every case is stats::aggregate() as
# R's own documentation and regression suite call it; the source is named in
# each case's `name` field, which the .t prints as the test description:
#
#   * src/library/stats/man/aggregate.Rd \examples -- state.x77 by Region and
#     by Region x Cold, the testDF/by1/by2 example in both of its forms, and the
#     chickwts, warpbreaks, airquality, esoph and iris formula examples.
#   * tests/reg-tests-1a.R -- the one-row result (Philippe Hupe, R-help
#     2004-05-14) and the f1 "converted to factors < 2.6.0" sum.
#   * tests/reg-tests-1c.R -- PR#15004 (21 grouping columns, where rounding
#     falsely merged groups) and PR#15699 (no grouping variables at all).
#   * tests/reg-tests-1d.R -- PR#17283, Population by Region x Cold.
#
# Normalisations, each so that an R answer is comparable with agg()'s at all:
#
#   * A factor is emitted as its labels and a logical as "TRUE"/"FALSE": agg()
#     groups on the stringified cell.
#   * R drops a group whose key has an NA unless the key is a factor with NA as
#     a level; agg() always keeps it.  The testDF example is therefore frozen
#     in its second, factor(exclude = "") form, which keeps them -- the first
#     form is the same answer with those groups removed.
#   * R's mean(x) is NA when x has an NA, which is agg()'s skipna => 0; with
#     na.rm = TRUE it is skipna => 1.  Each case records which.
#   * Where a case's FUN is not one of agg()'s names it is mapped onto the
#     equivalent one: length -> n, NROW -> n, sd -> sd.  `count` is
#     function(x) sum(!is.na(x)).
#   * PR#15699 draws its data from runif() and sample() unseeded; this freezes
#     the draw under set.seed(15699), since the bug was in the grouping, not in
#     the values.
#   * The comparison is by group, not by row order: aggregate() orders groups
#     with the first `by` variable varying fastest and factors in level order,
#     agg() sorts them lexicographically.  The order is pinned against pandas,
#     whose rule agg() follows, in the pandas block instead.
#
# Data are printed with the fewest significant digits that read back as the
# same double; expected values at 17.

pv <- function(x) {
	if (is.factor(x)) x <- as.character(x)
	if (is.logical(x)) x <- ifelse(is.na(x), NA, ifelse(x, "TRUE", "FALSE"))
	vapply(seq_along(x), function(i) {
		v <- x[[i]]
		if (is.na(v)) return("undef")
		if (is.character(v)) {
			v <- gsub("\\\\", "\\\\\\\\", v)
			v <- gsub("'", "\\\\'", v)
			return(paste0("'", v, "'"))
		}
		if (!is.finite(v)) stop("non-finite value: ", v)
		if (v == round(v) && abs(v) < 2^53) return(sprintf("%.0f", v))
		for (d in 1:17) {
			s <- sprintf("%.*g", d, v)
			if (as.numeric(s) == v) return(s)
		}
		stop("no round-trip for ", v)
	}, "")
}
pe <- function(x) {                  # expected values, full precision
	if (is.factor(x)) x <- as.character(x)
	if (is.character(x) || is.logical(x)) return(pv(x))
	vapply(x, function(v) if (is.na(v)) "undef" else sprintf("%.17g", v), "")
}
qk <- function(s) paste0("'", gsub("'", "\\\\'", s), "'")

emit <- function(name, data, by, agg, skipna, res, outmap) {
	# data: a data.frame of the columns used; by: names; agg: named list col ->
	# agg() function name; res: aggregate()'s result; outmap: agg() output
	# column -> column of res
	cat("\t{\n")
	cat("\t\tname   => ", qk(name), ",\n", sep = "")
	cat("\t\tcols   => [ ", paste(qk(names(data)), collapse = ", "), " ],\n", sep = "")
	cat("\t\tdata   => {\n")
	for (c in names(data))
		cat("\t\t\t", qk(c), " => [ ", paste(pv(data[[c]]), collapse = ", "), " ],\n", sep = "")
	cat("\t\t},\n")
	cat("\t\tby     => [ ", if (length(by)) paste(qk(by), collapse = ", "), " ],\n", sep = "")
	cat("\t\tagg    => { ", paste(sprintf("%s => %s", qk(names(agg)),
		vapply(agg, function(f) if (length(f) == 1) qk(f)
		       else paste0("[ ", paste(qk(f), collapse = ", "), " ]"), "")),
		collapse = ", "), " },\n", sep = "")
	cat("\t\tskipna => ", skipna, ",\n", sep = "")
	cat("\t\tgroups => [\n")
	for (i in seq_len(nrow(res))) {
		keys <- vapply(by, function(b) pe(res[[b]][i]), "")
		vals <- vapply(names(outmap), function(o) {
			sprintf("%s => %s", qk(o), pe(res[[outmap[[o]]]][i]))
		}, "")
		cat("\t\t\t[ [ ", paste(keys, collapse = ", "), " ], { ",
		    paste(vals, collapse = ", "), " } ],\n", sep = "")
	}
	cat("\t\t],\n")
	cat("\t},\n")
}

# one aggregate() per agg() function, merged on the keys: aggregate() itself
# takes a single FUN
multi <- function(df, by, cols, funs, na.rm) {
	out <- NULL
	for (f in names(funs)) {
		r <- aggregate(df[cols], by = df[by], FUN = funs[[f]])
		names(r)[match(cols, names(r))] <- paste0(cols, "\x01", f)
		out <- if (is.null(out)) r else merge(out, r, by = by, sort = FALSE)
	}
	out
}
count <- function(x) sum(!is.na(x))

# ---- aggregate.Rd: state.x77 by Region --------------------------------------
st <- data.frame(state.x77, check.names = FALSE)
st$Region <- as.character(state.region)
num <- colnames(state.x77)
r <- aggregate(st[num], list(Region = st$Region), mean)
emit("aggregate.Rd: state.x77 by Region, mean", st[c("Region", num)], "Region",
     setNames(as.list(rep("mean", length(num))), num), 1, r,
     setNames(as.list(num), num))

# ---- aggregate.Rd + reg-tests-1a.R: by Region x Cold ------------------------
st$Cold <- ifelse(state.x77[, "Frost"] > 130, "TRUE", "FALSE")
r <- aggregate(st[num], list(Region = st$Region, Cold = st$Cold), mean)
emit("aggregate.Rd / reg-tests-1a.R: state.x77 by Region x Cold, mean",
     st[c("Region", "Cold", num)], c("Region", "Cold"),
     setNames(as.list(rep("mean", length(num))), num), 1, r,
     setNames(as.list(num), num))

# ---- reg-tests-1d.R PR#17283: Population only, values pinned there too ------
r <- aggregate(st["Population"], list(Region = st$Region, Cold = st$Cold), mean)
emit("reg-tests-1d.R PR#17283: Population by Region x Cold",
     st[c("Region", "Cold", "Population")], c("Region", "Cold"),
     list(Population = "mean"), 1, r, list(Population = "Population"))

# ---- aggregate.Rd: testDF with NA keys kept (the factor(exclude="") form) ---
testDF <- data.frame(v1 = c(1,3,5,7,8,3,5,NA,4,5,7,9),
                     v2 = c(11,33,55,77,88,33,55,NA,44,55,77,99))
by1 <- c("red", "blue", 1, 2, NA, "big", 1, 2, "red", 1, NA, 12)
by2 <- c("wet", "dry", 99, 95, NA, "damp", 95, 99, "red", 99, NA, NA)
fby1 <- factor(by1, exclude = "")
fby2 <- factor(by2, exclude = "")
d <- data.frame(by1 = by1, by2 = by2, testDF)
r <- aggregate(x = testDF, by = list(by1 = fby1, by2 = fby2), FUN = "mean")
emit("aggregate.Rd: testDF by by1 x by2, NA as a level, mean (skipna => 0)",
     d, c("by1", "by2"), list(v1 = "mean", v2 = "mean"), 0, r,
     list(v1 = "v1", v2 = "v2"))
r <- aggregate(x = testDF, by = list(by1 = fby1, by2 = fby2), FUN = "mean",
               na.rm = TRUE)
r$v1[is.nan(r$v1)] <- NA          # mean(numeric(0)) is NaN; agg() gives undef
r$v2[is.nan(r$v2)] <- NA
emit("aggregate.Rd: testDF by by1 x by2, NA as a level, mean, na.rm (skipna => 1)",
     d, c("by1", "by2"), list(v1 = "mean", v2 = "mean"), 1, r,
     list(v1 = "v1", v2 = "v2"))

# ---- aggregate.Rd: chickwts, every numeric agg() function -------------------
cw <- data.frame(feed = as.character(chickwts$feed), weight = chickwts$weight)
funs <- list(mean = mean, median = median, sum = sum, sd = sd, var = var,
             min = min, max = max, n = length, count = count)
r <- multi(cw, "feed", "weight", funs)
emit("aggregate.Rd: weight ~ feed (chickwts), every reducer",
     cw, "feed", list(weight = names(funs)), 1, r,
     setNames(as.list(paste0("weight\x01", names(funs))),
              paste0("weight_", names(funs))))

# ---- aggregate.Rd: warpbreaks, two keys -------------------------------------
wb <- data.frame(wool = as.character(warpbreaks$wool),
                 tension = as.character(warpbreaks$tension),
                 breaks = warpbreaks$breaks)
r <- multi(wb, c("wool", "tension"), "breaks", list(mean = mean, sd = sd))
emit("aggregate.Rd: breaks ~ wool + tension (warpbreaks), mean and sd",
     wb, c("wool", "tension"), list(breaks = c("mean", "sd")), 1, r,
     list(breaks_mean = "breaks\x01mean", breaks_sd = "breaks\x01sd"))

# ---- aggregate.Rd: airquality, NA handled per variable ----------------------
aq <- airquality[c("Month", "Ozone", "Temp")]
f_na <- list(mean = function(x) mean(x, na.rm = TRUE),
             median = function(x) median(x, na.rm = TRUE),
             count = count, n = length)
r <- multi(aq, "Month", c("Ozone", "Temp"), f_na)
emit(paste("aggregate.Rd: cbind(Ozone, Temp) ~ Month (airquality),",
           "na.action = na.pass, na.rm = TRUE (skipna => 1)"),
     aq, "Month", list(Ozone = names(f_na), Temp = names(f_na)), 1, r,
     c(setNames(as.list(paste0("Ozone\x01", names(f_na))), paste0("Ozone_", names(f_na))),
       setNames(as.list(paste0("Temp\x01", names(f_na))), paste0("Temp_", names(f_na)))))
r <- multi(aq, "Month", c("Ozone", "Temp"), list(mean = mean))
emit(paste("aggregate.Rd: cbind(Ozone, Temp) ~ Month (airquality),",
           "na.action = na.pass, no na.rm (skipna => 0)"),
     aq, "Month", list(Ozone = "mean", Temp = "mean"), 0, r,
     list(Ozone = "Ozone\x01mean", Temp = "Temp\x01mean"))

# ---- aggregate.Rd: esoph, sum over two keys ---------------------------------
es <- data.frame(alcgp = as.character(esoph$alcgp), tobgp = as.character(esoph$tobgp),
                 ncases = esoph$ncases, ncontrols = esoph$ncontrols)
r <- aggregate(cbind(ncases, ncontrols) ~ alcgp + tobgp, data = es, sum)
emit("aggregate.Rd: cbind(ncases, ncontrols) ~ alcgp + tobgp (esoph), sum",
     es, c("alcgp", "tobgp"), list(ncases = "sum", ncontrols = "sum"), 1, r,
     list(ncases = "ncases", ncontrols = "ncontrols"))

# ---- aggregate.Rd: iris, dot notation ---------------------------------------
ir <- data.frame(Species = as.character(iris$Species), iris[1:4])
r <- aggregate(. ~ Species, data = ir, mean)
v <- names(iris)[1:4]
emit("aggregate.Rd: . ~ Species (iris), mean", ir, "Species",
     setNames(as.list(rep("mean", 4)), v), 1, r, setNames(as.list(v), v))

# ---- reg-tests-1a.R: a result of one row ------------------------------------
dat <- data.frame(a = rep(2, 10), b = rep("a", 10))
r <- aggregate(dat$a, by = list(a1 = dat$a, b1 = dat$b), NROW)
d <- data.frame(a1 = dat$a, b1 = dat$b, a = dat$a)
emit("reg-tests-1a.R: aggregate.data.frame with a one-row result (NROW -> n)",
     d, c("a1", "b1"), list(a = "n"), 1, r, list(a = "x"))

# ---- reg-tests-1a.R: sum over a character key -------------------------------
f1 <- c("a", "b", "a", "b")
r <- aggregate(1:4, list(groups = f1), sum)
emit("reg-tests-1a.R: aggregate(1:4, list(groups=f1), sum)",
     data.frame(groups = f1, x = 1:4), "groups", list(x = "sum"), 1, r, list(x = "x"))

# ---- reg-tests-1c.R PR#15004: 21 grouping columns ---------------------------
n <- 10; s <- 3; l <- 10000; m <- 20
x <- data.frame(x1 = 1:n, x2 = 1:n)
by <- data.frame(V1 = factor(rep(1:3, n %/% s + 1)[1:n], levels = 1:s))
for (i in 1:m) by[[i + 1]] <- factor(rep(l, n), levels = 1:l)
r <- aggregate.data.frame(x, by, mean)
d <- data.frame(lapply(by, as.character), x)
emit("reg-tests-1c.R PR#15004: 21 grouping columns, groups not falsely merged",
     d, names(by), list(x1 = "mean", x2 = "mean"), 1, r, list(x1 = "x1", x2 = "x2"))

# ---- reg-tests-1c.R PR#15699: no grouping variables -------------------------
set.seed(15699)
dat <- data.frame(Y = runif(10), X = sample(LETTERS[1:3], 10, TRUE))
r <- aggregate(Y ~ 1, FUN = mean, data = dat)
emit("reg-tests-1c.R PR#15699: Y ~ 1, no grouping variables",
     dat, character(0), list(Y = "mean"), 1, r, list(Y = "Y"))
