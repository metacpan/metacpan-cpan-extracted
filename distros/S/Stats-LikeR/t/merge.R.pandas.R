#!/usr/bin/env Rscript
#
# Regenerates the frozen R side of t/merge.R.pandas.t.  Re-run it with
#
#     Rscript t/merge.R.pandas.R > /tmp/merge.R.pl
#
# and paste the output over the "BEGIN GENERATED (R)" .. "END GENERATED (R)"
# block of t/merge.R.pandas.t.  The test itself never runs R: everything this
# prints is a Perl literal.
#
# Written against R 4.6.1 (2026-06-24).  Every case below is one of R's own
# regression tests (tests/reg-tests-1{a,b,d}.R, tests/reg-tests-2.R) or one of
# the examples in src/library/base/man/merge.Rd, whose printed output is pinned
# in tests/Examples/base-Ex.Rout.save.  The source is named in each case's
# `name` field, which the .t prints as the test description.  Where a case's
# data came from rnorm()/sample(), the random column is replaced by fixed
# integers -- the bug each of those cases was written for is in the matching,
# not in the payload -- and the substitution is noted at the case.
#
# Two deliberate restrictions on what may go in the corpus:
#
#   * Every cell is an integer or a string.  Stats::LikeR matches join keys on
#     the stringified cell and this file compares cells as strings, and a
#     non-integer double does not stringify the same on a double, long-double
#     and __float128 perl -- 0.2 prints as "0.2" at 15 significant digits and
#     "0.200000000000000011" at 18.  pv() below dies rather than emit one; the
#     .t covers double-valued keys separately, with dyadic literals.
#   * The join key rule is R's `incomparables = NA`, not R's default.  In
#     Stats::LikeR a key cell that is undef matches nothing (merge.Rd: "DBMSes
#     do not match NULL records, equivalent to incomparables = NA in R"), so
#     that is the R call this file freezes.  R accepts `incomparables` only for
#     a single-column `by`, so na_unmatched() below generalises it by
#     substituting a row-unique sentinel for each NA key cell before merging
#     and restoring NA afterwards -- the same rule for any number of key
#     columns and for the outer joins.  R's default (NA matches NA) is a real
#     divergence from Stats::LikeR and is recorded as such in the .t.

options(digits = 17, warn = 1)

## ------------------------------------------------------------ Perl emitters
pv <- function(x) {                      # one cell as a Perl literal
    if (length(x) != 1) stop("pv() wants a scalar, got length ", length(x))
    if (is.factor(x)) x <- as.character(x)
    if (is.na(x)) return("undef")
    if (is.numeric(x)) {
        if (x != round(x))
            stop("non-integer double ", x, " in the corpus; see the header")
        return(sprintf("%.0f", x))
    }
    paste0("'", gsub("'", "\\\\'", gsub("\\\\", "\\\\\\\\", as.character(x))), "'")
}
prow  <- function(v) paste0("[", paste(vapply(v, pv, ""), collapse = ", "), "]")
pname <- function(v) paste0("[", paste0("'", v, "'", collapse = ", "), "]")
pon   <- function(v) if (length(v) == 1) paste0("'", v, "'") else pname(v)

## A data frame as `<pfx>cols => [...], <pfx>rows => [[...], ...]`, indented by
## `ind`, with the rows after the first lined up under the first.
pframe <- function(df, ind, pfx = "") {
    cols <- names(df)
    rows <- character(nrow(df))
    for (i in seq_len(nrow(df)))
        rows[i] <- prow(lapply(cols, function(c) df[[c]][i]))
    pad <- strrep(" ", nchar(pfx) + nchar("rows => [ "))
    c(sprintf("%s%scols => %s,", ind, pfx, pname(cols)),
      if (nrow(df) == 0) sprintf("%s%srows => [],", ind, pfx)
      else c(sprintf("%s%srows => [ %s,", ind, pfx, rows[1]),
             if (nrow(df) > 1) sprintf("%s%s%s,", ind, pad, rows[-1]),
             sprintf("%s%s],", ind, substr(pad, 1, nchar(pad) - 2))))
}

## Frames are named once in %FRAMES and referenced by name, so the four `how`
## variants of one join do not repeat their inputs four times.
FRAMES <- character(0)
DFS    <- list()
frame <- function(nm, df) {
    if (is.null(DFS[[nm]])) {
        DFS[[nm]]  <<- df
        FRAMES    <<- c(FRAMES, sprintf("\t'%s' => {", nm), pframe(df, "\t\t"), "\t},")
    }
    invisible(nm)
}

CASES <- character(0)
emit <- function(name, lname, rname, args, want, shapes = NULL) {
    CASES <<- c(CASES,
        sprintf("\t{ name  => '%s',", gsub("'", "\\\\'", name)),
        sprintf("\t  left  => '%s', right => '%s',", lname, rname),
        sprintf("\t  args  => [ %s ],", args),
        if (!is.null(shapes)) sprintf("\t  shapes => '%s',", shapes),
        pframe(want, "\t  ", "want_"),
        "\t},")
}

## R's merge with Stats::LikeR's key rule: an NA key cell matches nothing at
## all, in either direction, for any number of key columns.  Each NA key cell
## becomes a sentinel unique to (side, row, column), so it can never equal a
## cell on the other side and never collides with real data; the sentinels are
## turned back into NA in the result.  For a single-column `by` this is exactly
## R's own `incomparables = NA`, which the .t also checks directly.
SENT <- "NA:"                   # not a value any corpus row carries
na_unmatched <- function(x, y, by.x, by.y, ...) {
    stamp <- function(df, keys, side) {
        for (k in keys) {
            col <- as.character(df[[k]])
            na  <- is.na(col)
            col[na] <- paste0(SENT, side, ":", which(na), ":", k)
            df[[k]] <- col
        }
        df
    }
    m <- merge(stamp(x, by.x, "x"), stamp(y, by.y, "y"),
               by.x = by.x, by.y = by.y, ...)
    for (j in seq_along(m)) {
        if (!is.character(m[[j]])) next
        m[[j]][startsWith(replace(m[[j]], is.na(m[[j]]), ""), SENT)] <- NA
    }
    m
}

## how => the R arguments naming the same join
ALLS <- list(inner = list(all.x = FALSE, all.y = FALSE),
             left  = list(all.x = TRUE,  all.y = FALSE),
             right = list(all.x = FALSE, all.y = TRUE),
             outer = list(all.x = TRUE,  all.y = TRUE))

## One case per `how`, with the keys named the same on both sides.
four <- function(name, ln, rn, on, shapes = NULL, ...) {
    for (how in names(ALLS)) {
        want <- do.call(na_unmatched, c(list(DFS[[ln]], DFS[[rn]],
                                             by.x = on, by.y = on),
                                        ALLS[[how]], list(...)))
        emit(sprintf("%s [%s]", name, how), ln, rn,
             sprintf("'how' => '%s', 'on' => %s", how, pon(on)), want, shapes)
    }
}
## The same, with the keys named differently on each side.
four_xy <- function(name, ln, rn, by.x, by.y, shapes = NULL, ...) {
    for (how in names(ALLS)) {
        want <- do.call(na_unmatched, c(list(DFS[[ln]], DFS[[rn]],
                                             by.x = by.x, by.y = by.y),
                                        ALLS[[how]], list(...)))
        emit(sprintf("%s [%s]", name, how), ln, rn,
             sprintf("'how' => '%s', 'left_on' => %s, 'right_on' => %s",
                     how, pon(by.x), pon(by.y)),
             want, shapes)
    }
}

## One case per `how` from R's own `incomparables = NA`, which R accepts only
## for a single-column `by`.  Where both routes are available they must give
## the same answer, so these cases also check na_unmatched()'s emulation.
four_inc <- function(name, ln, rn, on, shapes = NULL) {
    stopifnot(length(on) == 1)
    for (how in names(ALLS)) {
        want <- do.call(merge, c(list(DFS[[ln]], DFS[[rn]], by = on,
                                      incomparables = NA), ALLS[[how]]))
        emit(sprintf("%s [%s]", name, how), ln, rn,
             sprintf("'how' => '%s', 'on' => %s", how, pon(on)), want, shapes)
    }
}

## ------------------------------------------------------------------- corpus
## Every frame is registered under a name and referenced by it, so the four
## `how` variants of one join do not repeat their inputs four times.

## src/library/base/man/merge.Rd, the examples.  authorN and books share
## exactly one column name, so the natural join and on => 'name' must agree.
authors <- data.frame(
    surname     = c("Tukey", "Venables", "Tierney", "Ripley", "McNeil"),
    nationality = c("US", "Australia", "US", "UK", "Australia"),
    deceased    = c("yes", rep("no", 4)))
books <- data.frame(
    name = c("Tukey", "Venables", "Tierney",
             "Ripley", "Ripley", "McNeil", "R Core"),
    title = c("Exploratory Data Analysis",
              "Modern Applied Statistics ...",
              "LISP-STAT",
              "Spatial Statistics", "Stochastic Simulation",
              "Interactive Data Analysis",
              "An Introduction to R"),
    other.author = c(NA, "Ripley", NA, NA, NA, NA,
                     "Venables & Smith"))
frame("authors", authors)
frame("authorN", within(authors, { name <- surname; rm(surname) }))
frame("books",   books)

four("merge.Rd m0: merge(authorN, books)", "authorN", "books", "name")
emit("merge.Rd m0: natural join, the intersection is {name}", "authorN", "books",
     "'how' => 'inner'", na_unmatched(DFS$authorN, DFS$books, "name", "name"))
four_xy("merge.Rd m1: merge(authors, books, by.x = 'surname', by.y = 'name')",
        "authors", "books", "surname", "name")
four_xy("merge.Rd m2: merge(books, authors, by.x = 'name', by.y = 'surname')",
        "books", "authors", "name", "surname")

## merge.Rd's Cartesian-product check, dim(merge(m1, m2, by = NULL)).  m1 and
## m2 hold the same five columns under five shared names, so every column of
## the cross join collides and the whole output is suffixed.
frame("m1", merge(authors, books, by.x = "surname", by.y = "name"))
frame("m2", merge(books, authors, by.x = "name", by.y = "surname"))
emit("merge.Rd: merge(m1, m2, by = NULL) is the Cartesian product",
     "m1", "m2", "'how' => 'cross'", merge(DFS$m1, DFS$m2, by = NULL))

## tests/reg-tests-2.R, "moved from merge.Rd": b2 renames books' first column
## to authors', so the natural join key is `surname`.
b2 <- books; names(b2)[1] <- names(authors)[1]
frame("b2",    b2)
frame("b2_R7", b2[7, ])
four("reg-tests-2.R: merge(authors, b2)", "authors", "b2", "surname")
## and against b2's last row alone -- "R Core" is in no author, so the inner
## join is empty and only all.y keeps anything.
four("reg-tests-2.R: merge(authors, b2[7, ]), an empty inner join",
     "authors", "b2_R7", "surname")

## tests/reg-tests-1d.R, "merge() names when by.y": all four of these gave a
## duplicated column `name` with a warning in R <= 3.4.x.  The right frame's
## non-key `name` column collides with the output key column, which carries the
## left key's name, so R (>= 3.5.0, no.dups = TRUE) suffixes it to name.y.
## R's own stopifnot() over these four is worth reading beside the table below:
## it asserts identical(m, m_.) (inner == all.y), identical(m._, m__)
## (all.x == all = TRUE), identical(names(m), names(m__)) and
## identical(dim(m), c(3L, 6L)) -- all four of which the frozen answers keep.
frame("parents", data.frame(name = c("Sarah", "Max", "Qin", "Lex"),
                            sex = c("F", "M", "F", "M"), age = c(41, 43, 36, 51)))
frame("children", data.frame(parent = c("Sarah", "Max", "Qin"),
                             name = c("Oliver", "Sebastian", "Kai-lee"),
                             sex = c("M", "M", "F"), age = c(5, 8, 7)))
four_xy("reg-tests-1d.R: by.x = 'name', by.y = 'parent' (right 'name' collides)",
        "parents", "children", "name", "parent")

## tests/reg-tests-2.R, ggrothendieck 2002-03-16: every column is a join key,
## and 1.4.1 "got confused by inconsistencies in as.character".
d.df <- data.frame(x = 1:3, y = c("A", "D", "E"), z = c(6, 9, 10))
frame("d.df",    d.df)
frame("d.df_R1", d.df[1, ])
four("reg-tests-2.R: merge(d.df[1, ], d.df), all three columns are keys",
     "d.df_R1", "d.df", c("x", "y", "z"))

## tests/reg-tests-1a.R, "merging when NA is a level": b's y column holds the
## two-character string "NA" for x = 1 and a genuine missing value for x = 4.
## Level NA leaked into the answer in R 1.3.1.
frame("na_lvl_a", data.frame(x = 1:4))
frame("na_lvl_b", data.frame(x = 1:3, y = c("NA", "a", "b")))
four("reg-tests-1a.R: the string 'NA' is not a missing value",
     "na_lvl_a", "na_lvl_b", "x")

## tests/reg-tests-1a.R, PR#1510: multiple match rows with the keys named
## differently on the two sides.  Failed in R 1.5.0.  df1$w and df2$y were
## rnorm(10); they are fixed integers here.
frame("pr1510_df1", data.frame(z = c(1, 1, 2, 3, 5), m = c("a", "a", "b", "c", "e"),
                               w = 101:105))
frame("pr1510_df2", data.frame(x = c(1, 2, 2, 3, 9), y = 201:205,
                               n = c("a", "b", "b", "c", "z")))
four_xy("reg-tests-1a.R PR#1510: by.x = c('x','n'), by.y = c('z','m')",
        "pr1510_df2", "pr1510_df1", c("x", "n"), c("z", "m"))

## tests/reg-tests-1a.R: merge.data.frame was not making column names unique
## when doing a Cartesian product -- both were `col` in R 2.3.0.
DF <- data.frame(col = 1:3)
frame("DF", DF)
emit("reg-tests-1a.R: cross join suffixes the colliding column", "DF", "DF",
     "'how' => 'cross'", merge(DF, DF, by = numeric(0)))

## tests/reg-tests-1b.R, "regression tests for merge": d1 already carries a
## column named b.x, so the default suffixes cannot be used (R warns, and
## Stats::LikeR croaks -- checked in the .t).  suffixes = c("", ".y") works.
d1 <- data.frame(a = 1:5, b = 1:5, b.x = 5:1)
d2 <- data.frame(a = 1:5, b = 101:105)
frame("sfx_d1", d1)
frame("sfx_d2", d2)
for (how in names(ALLS)) {
    want <- do.call(merge, c(list(d1, d2, by = "a", suffixes = c("", ".y")),
                             ALLS[[how]]))
    emit(sprintf("reg-tests-1b.R: suffixes = c('', '.y') [%s]", how),
         "sfx_d1", "sfx_d2",
         sprintf("'how' => '%s', 'on' => 'a', 'suffixes' => ['', '.y']", how),
         want)
}

## tests/reg-tests-1b.R, the SDMTools::compare.matrix example: a two-column
## natural join where the whole of x is key.
frame("egrid", expand.grid(x = 1:2, y = 1:2))
frame("egrid_z", data.frame(x = c(1, 2, 1, 2), y = c(1, 1, 2, 2),
                            z = c(5040, 128, 1123, 3709)))
four("reg-tests-1b.R: two-column natural join, x is all key",
     "egrid", "egrid_z", c("x", "y"))

## tests/reg-tests-1a.R: two character matrices coerced to data frames, sharing
## only P and V.  Failed for a while pre-2.0.0.  Note the column names "2" and
## "1", which are numbers on the Perl side too.
frame("matP", as.data.frame(structure(c("a", "b", "2", "0.2-26", "O", "O"),
              dim = 2:3, dimnames = list(c("1", "2"), c("P", "V", "2")))))
frame("matQ", as.data.frame(structure(c("a", "b", "2", "0.2-25", "O", "O"),
              dim = 2:3, dimnames = list(c("1", "2"), c("P", "V", "1")))))
four("reg-tests-1a.R: matrices sharing {P, V}, columns named '2' and '1'",
     "matP", "matQ", c("P", "V"))

## tests/reg-tests-1b.R: zero-row frames.  merge(NULL, women) and merge(women,
## NULL) failed in R 2.7.0.  An empty AoH carries no column names at all, so
## these run as HoA only; the .t pins what the AoH form does instead.
women <- data.frame(height = 58:72,
                    weight = c(115, 117, 120, 123, 126, 129, 132, 135,
                               139, 142, 146, 150, 154, 159, 164))
frame("women",  women)
frame("women0", women[FALSE, ])
four("reg-tests-1b.R: merge(women[FALSE, ], women)", "women0", "women",
     c("height", "weight"), shapes = "hoa")
four("reg-tests-1b.R: merge(women, women[FALSE, ])", "women", "women0",
     c("height", "weight"), shapes = "hoa")

## tests/reg-tests-1a.R, "merge on zero-row data frames": not allowed <= 2.4.0.
## sample(L3, 1) is replaced by a fixed level.
d <- data.frame(x = 1, y = 1, fac = "B")
frame("zr_d", d)
frame("zr_e", d[-1, ])
four_xy("reg-tests-1a.R: merge on a zero-row right frame, by.x = by.y = 'x'",
        "zr_d", "zr_e", "x", "x", shapes = "hoa")

## src/library/base/man/merge.Rd, the `incomparables` example.  R's default
## matches NA to NA, which Stats::LikeR does not; these are the
## incomparables = NA answers, and the .t checks the single-column ones against
## R's own incomparables = NA call as well.
frame("inc_x", data.frame(k1 = c(NA, NA, 3, 4, 5), k2 = c(1, NA, NA, 4, 5),
                          data = 1:5))
frame("inc_y", data.frame(k1 = c(NA, 2, NA, 4, 5), k2 = c(NA, NA, 3, 4, 5),
                          data = 1:5))
four("merge.Rd incomparables: by = c('k1','k2'), NA matches nothing",
     "inc_x", "inc_y", c("k1", "k2"))
four("merge.Rd incomparables: by = 'k1', NA matches nothing",
     "inc_x", "inc_y", "k1")
four("merge.Rd incomparables: by = 'k2', NA matches nothing",
     "inc_x", "inc_y", "k2")
## the same two joins straight from R's `incomparables = NA`, which is the line
## merge.Rd itself runs: merge(x, y, by = "k2", incomparables = NA) # 2 rows
four_inc("merge.Rd: R's own incomparables = NA, by = 'k1'", "inc_x", "inc_y", "k1")
four_inc("merge.Rd: R's own incomparables = NA, by = 'k2'", "inc_x", "inc_y", "k2")

## ------------------------------------------------------------------- output
cat("# BEGIN GENERATED (R) -- Rscript t/merge.R.pandas.R\n")
cat(sprintf("# %d frames and %d cases, from R %s\n",
            sum(startsWith(FRAMES, "\t'")),
            sum(startsWith(CASES, "\t{ name")),
            paste0(R.version$major, ".", R.version$minor)))
cat("my %R_FRAMES = (\n")
cat(FRAMES, sep = "\n")
cat(");\n\nmy @R_CASES = (\n")
cat(CASES, sep = "\n")
cat(");\n")
cat("# END GENERATED (R)\n")
