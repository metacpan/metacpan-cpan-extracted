# Generates the expected values frozen in t/lm.design.R.t.  Run: Rscript t/lm.design.R.R (R 4.6.1);
# the first block prints the table rows, the rest the NA-level and predict() values.
options(digits=17)
d=data.frame(y=c(1.2,2.9,3.1,4.8,5.2,6.9,7.1,8.4,9.9,10.3,11.8,12.1),
 x=c(1,2.5,3,4.5,5,6.5,7,8.5,9,10.5,11,12.5),
 z=c(2,3,5,4,6,8,7,9,12,11,13,15.5),
 a=rep(c("p","q","r"),4), b=rep(c("u","v"),each=6), one="s")
forms=c("y~x+b:x-1","y~x/a-1","y~x+z+b:x-1","y~x+a:b-1","y~a:b+x-1","y~a+b-1","y~a*a","y~a:a","y~b+b*b","y~(a+b)^3","y~a+a:a+x")
for(f in forms){m=lm(as.formula(f),d); cf=coef(m)
 cat("\t[ '",f,"', [",paste0("'",sub("(Intercept)","Intercept",names(cf),fixed=TRUE),"'",collapse=", "),"], [",
  paste(ifelse(is.na(cf),"'NaN'",sprintf("%.17g",cf)),collapse=", "),"], ",m$rank,", ",m$df.residual," ],\n",sep="")}
# bug 1
e=data.frame(y=c(1.1,3.2,2.1,5.3,4.4,7.2,6.1,9.5,8.3,3.3),x=c(1,2,NA,4,5,6.5,7,9,8,3),a=c("q","q","p","q","r","r","q","r","q","r"))
m=lm(y~a+x,e); cat("NA x:",sprintf("%.17g",coef(m)),"\n",paste(m$xlevels$a),"\n")
e2=e; e2$x=c(1,2,3,4,5,6.5,7,9,8,3); e2$y[3]=NA
m=lm(y~a+x,e2); cat("NA y:",sprintf("%.17g",coef(m)),"\n",paste(m$xlevels$a),"\n")
# bug 5 predict
d$u=d$z
nd=data.frame(x=c(2.5,6.5,9.5), a=c("q","p","r"), z=c(3.5,6,10))
for(s in c("y~a*log(x)","y~exp(x/10):a","y~sqrt(z):a")){m=lm(as.formula(s),d); cat(s,sprintf("%.17g",predict(m,nd)),"\n")}
d$g=rep(c("p","q:r","s"),4); nd$g=c("q:r","p","s")
m=lm(y~g*x,d); cat("g*x",sprintf("%.17g",predict(m,nd)),"\n"); print(sprintf("%.17g",coef(m)))
