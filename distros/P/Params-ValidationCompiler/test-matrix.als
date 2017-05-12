one sig Validator {
	style: Style,
	specs: set Spec,
	slurpy: Slurpy,
}

abstract sig Slurpy { }

enum Style { named, positional, named_to_list }

sig Spec {
	is_required: Bool,
	type: Type,
	default: Default,
}

enum Bool { false, true }

enum Default { absent, simple, coderef }

sig Type extends Slurpy {
	system: TypeSystem,
	inlinable: Inlinable,
     coercions: set Coercion,
}

enum TypeSystem { moose, specio, type_tiny}

enum Inlinable { cannot, yes, with_env }

sig Coercion {
	inlinable: Inlinable,
}

run {} for 5
