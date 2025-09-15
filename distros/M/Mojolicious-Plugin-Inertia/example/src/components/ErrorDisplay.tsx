interface Props {
  errors: Record<string, string>
}

export default function ErrorDisplay({ errors }: Props) {
  if (!errors || Object.keys(errors).length === 0) {
    return null
  }

  return (
    <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-4">
      <h3 className="text-sm font-semibold text-red-800 mb-2">
        Please correct the following errors:
      </h3>
      <ul className="list-disc list-inside space-y-1">
        {Object.entries(errors).map(([field, message]) => (
          <li key={field} className="text-sm text-red-600">
            <span className="font-medium">{field}:</span> {message}
          </li>
        ))}
      </ul>
    </div>
  )
}